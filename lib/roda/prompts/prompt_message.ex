defmodule Roda.Prompts.PromptMessage do
  use Ecto.Schema
  import Ecto.Changeset

  alias Roda.Prompts.PromptConversation

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}

  schema "prompt_messages" do
    field :role, :string
    field :content, :string

    belongs_to :conversation, PromptConversation, type: :binary_id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Creates a changeset for a new message.
  """
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:role, :content, :conversation_id])
    |> validate_required([:role, :content, :conversation_id])
    |> validate_inclusion(:role, ["user", "assistant", "system"])
    |> foreign_key_constraint(:conversation_id)
  end
end
