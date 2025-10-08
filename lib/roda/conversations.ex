defmodule Roda.Conversations do
  alias Roda.Repo
  alias Roda.Conversations.{Chunk, Conversation}

  def add_chunk(attrs) do
    Chunk.changeset(attrs)
    |> Repo.insert!()
  end

  def add_conversation(attrs) do
    Conversation.changeset(attrs)
    |> Repo.insert!()
  end
end
