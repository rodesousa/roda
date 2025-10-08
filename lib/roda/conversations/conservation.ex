defmodule Roda.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Conversations.Chunk

  schema "conversations" do
    has_many :chunks, Chunk

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
  end
end
