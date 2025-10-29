defmodule Roda.Conversations do
  alias Roda.Repo
  alias Roda.Conversations.{Chunk, Conversation}
  import Ecto.Query

  def add_chunk!(attrs) do
    Chunk.changeset(attrs)
    |> Repo.insert!()
  end

  def add_conversation!(attrs) do
    Conversation.changeset(attrs)
    |> Repo.insert!()
  end

  def get_chunk(chunk_id) do
    Chunk
    |> where([c], c.id == ^chunk_id)
    |> preload(:conversation)
    |> Repo.one()
  end

  def get_conversation(conversation_id) do
    Conversation
    |> where([c], c.id == ^conversation_id)
    |> preload(:project)
    |> preload(:chunks)
    |> Repo.one()
  end

  def list_conversations_by_project_id(project_id) do
    Conversation
    |> where([c], c.project_id == ^project_id)
    |> preload(:chunks)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_conversation_minio_path(conversation_id) do
    case get_conversation(conversation_id) do
      nil ->
        {:error, nil}

      conversation ->
        {:ok,
         "org_#{conversation.project.organization_id}/proj_#{conversation.project.id}/conv_#{conversation.id}"}
    end
  end

  def get_chunk_by_ids(ids) do
    Chunk
    |> where([c], c.id in ^ids)
    |> select([c], %{id: c.id, text: c.text})
    |> Repo.all()
  end
end
