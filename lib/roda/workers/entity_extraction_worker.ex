defmodule Roda.Workers.EntityExtractionWorker do
  @moduledoc """
  Extracts entities from conversation chunks and stores them in Memgraph with 4-level deduplication.
  """
  use Oban.Worker,
    queue: :entity_extraction,
    max_attempts: 3

  alias Roda.{Repo, Organization, LLM, Conversations}
  alias Roda.Organization.Organization
  alias Roda.Conversations.Chunk
  alias Roda.LLM.Provider
  alias Roda.Memgraph
  require Logger

  defp entity_extraction_prompt(input_text) do
    """
    <role>
    You are a Knowledge Graph Specialist responsible for extracting entities from input text.
    </role>

    <instructions>
    - Identify clearly defined entities in the text
    - Extract for each entity:
      * `entity_name`: Title case. Use CONSISTENT naming (e.g., always "IBM" not "IBM Corporation" in one place and "IBM" in another)
      * `entity_type`: One of [PERSON, ORGANIZATION, LOCATION, EVENT, CONCEPT, TECHNOLOGY, PRODUCT, OTHER]
      * `entity_description`: Concise description based ONLY on the input text

    - **Output Format:** Each entity on ONE line, 4 fields separated by pipe `|`:
      ```
      entity|entity_name|entity_type|entity_description
      ```
    </instructions>

    <critical_rules>
    🚨 FOLLOW THESE RULES EXACTLY - DO NOT DEVIATE:

    1. Extract ONLY the entity name AS WRITTEN in the text
       - Text says "Macron" → Extract "Macron" (NOT "Emmanuel Macron")
       - Text says "IBM" → Extract "IBM" (NOT "International Business Machines")

    2. Do NOT add information from your knowledge
       - Do NOT expand names, add first names, last names, or titles not in the text
       - Do NOT use your world knowledge to "complete" names

    3. Entity types MUST be one of:
       [PERSON, ORGANIZATION, LOCATION, EVENT, CONCEPT, TECHNOLOGY, PRODUCT, OTHER]

    4. Output format (one entity per line, pipe-separated):
       entity|Name|Type|Description

    5. Output PLAIN TEXT only (no markdown, no backticks, no code blocks).

    6. Output language MUST match the input text language:
     - French text → French descriptions
     - English text → English descriptions
     - Keep entity names in their original language (proper nouns)
    </critical_rules>

    <examples>
    Example 1:
    Input: "Sarah presented the new AI algorithm at the conference. The machine learning approach reduces errors by 40%."
    Output:
    entity|Sarah|PERSON|Sarah is a person who presented an AI algorithm at a conference
    entity|AI algorithm|TECHNOLOGY|AI algorithm is a new technology presented by Sarah
    entity|Machine learning approach|CONCEPT|Machine learning approach is a method that reduces errors by 40%
    entity|Conference|EVENT|Conference is an event where Sarah presented the AI algorithm

    Example 2:
    Input: "Macron n'a pas évoqué la dissolution lors de son rendez-vous mardi avec Yaël Braun-Pivet. «Ce qui est sûr c'est que ça ne résoudra rien», est convaincue la présidente de l'Assemblée nationale. «Il ne faut pas déstabiliser nos institutions, soyons lucides, soyons responsables, gardons nos nerfs.»"

    Output:
    entity|Macron|PERSON|Macron est une personnalité politique qui a rencontré Yaël Braun-Pivet
    entity|Yaël Braun-Pivet|PERSON|Yaël Braun-Pivet est la présidente de l'Assemblée nationale qui pense que la dissolution ne résoudra rien
    entity|Assemblée nationale|ORGANIZATION|Assemblée nationale est l'institution législative dont Yaël Braun-Pivet est la présidente
    entity|Dissolution|CONCEPT|Dissolution est une mesure politique que Macron n'a pas évoquée et que Yaël Braun-Pivet pense inefficace
    entity|Stabilité institutionnelle|CONCEPT|Stabilité institutionnelle est une préoccupation exprimée par Yaël Braun-Pivet qui met en garde contre la déstabilisation des institutions

    </examples>

    <text>
    #{input_text}
    </text>
    """
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "organization_id" => org_id,
          "chunk_id" => chunk_id
        }
      }) do
    Logger.info("Extracting entities from chunk #{chunk_id}")

    with {:ok, chunk} <- get_chunk(chunk_id),
         {:ok, organization} <- get_organization(org_id),
         {:ok, provider} <- get_provider(organization),
         {:ok, entities} <- extract_entities(provider, chunk.text),
         :ok <-
           Memgraph.store_entities_with_deduplication(
             chunk,
             entities,
             organization
           ) do
      Logger.info("Successfully extracted entities from chunk #{chunk_id}")

      :ok
    else
      {:error, reason} = error ->
        Logger.error("Failed to extract entities: #{inspect(reason)}")
        error
    end
  end

  defp get_chunk(chunk_id) do
    case Conversations.get_chunk(chunk_id) do
      nil -> {:error, :chunk_not_found}
      chunk -> {:ok, chunk}
    end
  end

  defp get_organization(org_id) do
    case Repo.get(Organization, org_id) do
      nil -> {:error, :organization_not_found}
      org -> {:ok, org}
    end
  end

  defp get_provider(%Organization{} = organization) do
    case Roda.Providers.get_provider_by_organization(organization) do
      nil -> {:error, :provider_not_found}
      provider -> {:ok, provider}
    end
  end

  # defp extract_entities(%Provider{} = provider, text) do
  #     prompt = entity_extraction_prompt(text)
  #
  #     case LLM.chat_completion(provider, prompt) do
  #       nil ->
  #         {:error, :extraction_failed}
  #
  #       response ->
  #         entities = parse_entities(response)
  #         {:ok, entities}
  #     end
  #   end

  defp extract_entities(%Provider{} = provider, text) do
    entities = [
      %{
        description:
          "Mathilde Panot est une députée et présidente du groupe LFI à l'Assemblée nationale",
        name: "Mathilde Panot",
        type: "PERSON"
      },
      %{
        description:
          "Apolline de Malherbe est une journaliste qui a interrogé Mathilde Panot sur BFM TV",
        name: "Apolline de Malherbe",
        type: "PERSON"
      },
      %{
        description: "BFM TV est une chaîne de télévision où Mathilde Panot a été interrogée",
        name: "BFM TV",
        type: "ORGANIZATION"
      },
      %{
        description:
          "Groupe LFI est un groupe politique à l'Assemblée nationale dont Mathilde Panot est la présidente",
        name: "Groupe LFI",
        type: "ORGANIZATION"
      },
      %{
        description:
          "Assemblée nationale est l'institution législative où Mathilde Panot est députée et présidente du groupe LFI",
        name: "Assemblée nationale",
        type: "ORGANIZATION"
      },
      %{
        description:
          "Gouvernement socialiste est une hypothèse politique à laquelle Mathilde Panot dit ne pas croire",
        name: "Gouvernement socialiste",
        type: "CONCEPT"
      }
    ]

    {:ok, entities}
  end

  defp parse_entities(response) do
    response
    |> String.replace("```", "")
    |> String.split("\n", trim: true)
    |> Enum.filter(&String.starts_with?(&1, "entity|"))
    |> Enum.map(&parse_entity_line/1)
    |> Enum.filter(&(&1 != nil))
    |> IO.inspect(label: " after parse")
  end

  defp parse_entity_line(line) do
    case String.split(line, "|", trim: true) do
      ["entity", name, type, description] ->
        %{
          name: String.trim(name),
          type: String.trim(type),
          description: String.trim(description)
        }

      _ ->
        nil
    end
  end
end
