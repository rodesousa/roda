defmodule Roda.Conversations.Embedding.Embedding1024 do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Conversations.Chunk

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "embeddings_1024" do
    field :model, :string
    field :embedding, Pgvector.Ecto.Vector
    belongs_to :chunk_id, Chunk

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:chunk_id, :model, :embedding])
  end
end
