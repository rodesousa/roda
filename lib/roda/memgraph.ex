defmodule Roda.Memgraph do
  @moduledoc """
  Memgraph graph database interface using Bolt.Sips.
  """

  require Logger
  alias Roda.Organizations.Organization
  alias Roda.Conversations.Conversation

  @doc """
  Returns a connection from the Bolt.Sips pool.

  ## Example

  iex> Roda.Memgraph.conn()
  #PID<0.123.0>
  """
  def conn do
    Bolt.Sips.conn()
  end

  @doc """
  Executes a Cypher query and returns the result.

  ## Example

  iex> Roda.Memgraph.query("RETURN 1 AS num")
  {:ok, %Bolt.Sips.Response{results: [%{"num" => 1}]}}
  """
  def query(statement, params \\ %{}) do
    Bolt.Sips.query(conn(), statement, params)
  end

  @doc """
  Executes a Cypher query and returns the result or raises on error.

  ## Example

  iex> Roda.Memgraph.query!("CREATE (p:Person {name: $name}) RETURN p", %{name: "Alice"})
  %Bolt.Sips.Response{results: [%{"p" => ...}]}
  """
  def query!(statement, params \\ %{}) do
    Bolt.Sips.query!(conn(), statement, params)
  end

  @doc """
  Stores entities from a conversation in Memgraph with deduplication.

  Creates the conversation node if it doesn't exist, then performs entity deduplication
  at the project level. If an entity already exists in the project, it links the existing
  entity to the conversation. Otherwise, it creates a new entity node.

  This function is idempotent - if the conversation has already been processed, it skips
  processing and returns :ok.

  **IMPORTANT:** This function should ONLY be called from `Roda.Workers.EntityExtractionWorker`.
  Do not call this function directly from other parts of the application.

  ## Deduplication

  Level 1 (Hash-based) - **Currently implemented**:
  - Computes `entity_dedup_hash` from `name + type`
  - Searches for existing entities in the same project
  - Links to existing entity if found, creates new one otherwise

  Level 1.5 (String similarity) - **Future implementation**:
  - Uses Jaro-Winkler distance on `entity_normalized_name`
  - Detects typos and variations (e.g., "Marie Dubois" vs "Marie Duboi")

  Level 2 (Vector search) - **Future implementation**:
  - Semantic similarity using entity embeddings
  - Detects synonyms and related concepts (e.g., "IBM" vs "International Business Machines")

  Level 3 (Metadata boost) - **Future implementation**:
  - Context-aware scoring based on conversation proximity
  - Penalizes ambiguous names in different contexts

  Level 4 (LLM decision) - **Future implementation**:
  - LLM-powered final decision for gray zone cases
  - Conservative approach with async human review

  ## Example

      iex> conversation = %Conversation{id: "conv-123", project_id: "proj-1"}
      iex> entities = [
      ...>   %{name: "Marie Dubois", type: "PERSON", description: "French politician"},
      ...>   %{name: "Paris", type: "LOCATION", description: "Capital of France"}
      ...> ]
      iex> organization = %Organization{id: "org-1"}
      iex> Roda.Memgraph.store_conversation_entities(conversation, entities, organization)
      :ok
  """
  def store_conversation_entities(
        %Conversation{} = conversation,
        entities,
        %Organization{} = organization
      ) do
    case conversation_exists?(conversation.id) do
      true ->
        Logger.info("Conversation #{conversation.id} already processed in Memgraph, skipping")
        :ok

      false ->
        do_store_conversation_entities(conversation, entities, organization)
    end
  end

  defp conversation_exists?(conversation_id) do
    query = """
    MATCH (c:Conversation {id: $conversation_id})
    RETURN c.id
    LIMIT 1
    """

    case query(query, %{conversation_id: conversation_id}) do
      {:ok, %Bolt.Sips.Response{results: [_]}} ->
        true

      _ ->
        false
    end
  end

  defp do_store_conversation_entities(
         %Conversation{} = conversation,
         entities,
         %Organization{} = organization
       ) do
    project_id = conversation.project_id

    # Create Conversation node first
    create_conversation_node(conversation.id, project_id)

    Enum.each(entities, fn entity ->
      entity_dedup_hash = compute_entity_dedup_hash(entity.name, entity.type)
      entity_normalized_name = normalize_name(entity.name)

      case find_by_hash(project_id, entity_dedup_hash) do
        {:ok, existing_entity_id} ->
          {:ok, _} = link_entity_to_conversation(existing_entity_id, conversation.id)

        {:not_found} ->
          {:ok, _} =
            create_new_entity(
              organization.id,
              project_id,
              conversation.id,
              entity,
              entity_dedup_hash,
              entity_normalized_name
            )
      end
    end)

    :ok
  end

  defp create_conversation_node(conversation_id, project_id) do
    query = """
    CREATE (c:Conversation {
      id: $conversation_id,
      project_id: $project_id,
      created_at: datetime()
    })
    RETURN c.id
    """

    params = %{
      conversation_id: conversation_id,
      project_id: project_id
    }

    case query(query, params) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp compute_entity_dedup_hash(name, type) do
    normalized = "#{String.downcase(String.trim(name))}_#{String.downcase(type)}"
    :crypto.hash(:sha256, normalized) |> Base.encode16(case: :lower)
  end

  defp normalize_name(name) do
    name
    |> String.trim()
    |> String.downcase()
  end

  defp link_entity_to_conversation(entity_id, conversation_id) do
    query = """
    MATCH (e:Entity {id: $entity_id})
    MATCH (c:Conversation {id: $conversation_id})
    MERGE (e)-[:MENTIONED_IN]->(c)
    """

    params = %{entity_id: entity_id, conversation_id: conversation_id}
    query(query, params)
  end

  defp create_new_entity(
         org_id,
         project_id,
         conversation_id,
         entity,
         entity_dedup_hash,
         entity_normalized_name
       ) do
    entity_id = Uniq.UUID.uuid7()

    query = """
    CREATE (e:Entity {
      id: $id,
      organization_id: $organization_id,
      project_id: $project_id,
      name: $name,
      type: $type,
      description: $description,
      entity_dedup_hash: $entity_dedup_hash,
      entity_normalized_name: $entity_normalized_name,
      created_at: datetime(),
      updated_at: datetime()
    })
    WITH e
    MATCH (c:Conversation {id: $conversation_id})
    CREATE (e)-[:MENTIONED_IN]->(c)
    RETURN e.id
    """

    params = %{
      id: entity_id,
      organization_id: org_id,
      project_id: project_id,
      name: entity.name,
      type: entity.type,
      description: entity.description,
      entity_dedup_hash: entity_dedup_hash,
      entity_normalized_name: entity_normalized_name,
      conversation_id: conversation_id
    }

    case query(query, params) do
      {:ok, _} ->
        {:ok, entity_id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_by_hash(project_id, entity_dedup_hash) do
    query = """
    MATCH (e:Entity {project_id: $project_id, entity_dedup_hash: $entity_dedup_hash})
    RETURN e.id AS entity_id
    LIMIT 1
    """

    case query(query, %{project_id: project_id, entity_dedup_hash: entity_dedup_hash}) do
      {:ok, %Bolt.Sips.Response{results: [%{"entity_id" => id}]}} ->
        {:ok, id}

      _ ->
        {:not_found}
    end
  end
end
