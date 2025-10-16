defmodule Roda.Conversations.Chunk do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Conversations.Conversation

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "chunks" do
    field :text, :string
    field :position, :integer
    field :path, :string

    belongs_to :conversation, Conversation, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:conversation_id, :position, :text])
  end
end
