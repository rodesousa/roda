defmodule Roda.Conversations.Chunk do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Conversations.Conversation

  schema "chunks" do
    field :text, :string
    field :position, :integer

    belongs_to :conversation, Conversation

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:conversation_id, :position, :text])
  end
end
