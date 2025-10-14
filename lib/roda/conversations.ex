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
end
