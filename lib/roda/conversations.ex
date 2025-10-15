defmodule Roda.Conversations do
  alias Roda.Repo
  alias Roda.Conversations.{Chunk, Conversation}
  import Ecto.Query

  def add_chunk(attrs) do
    Chunk.changeset(attrs)
    |> Repo.insert!()
  end

  def add_conversation(attrs) do
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
    |> Repo.one()
  end

  def get_conversation_minio_path(conversation_id) do
    case get_conversation(conversation_id) do
      nil -> {:error, nil}
      conversation ->
        {:ok, "org_#{conversation.project.organization_id}/proj_#{conversation.project.id}/conv_#{conversation.id}"}
    end
  end
end
