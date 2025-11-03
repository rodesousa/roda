defmodule Roda.Prompts.PromptConversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Roda.Organizations.Project
  alias Roda.Prompts.PromptMessage

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "prompt_conversations" do
    field :title, :string
    field :begin_at, :naive_datetime
    field :end_at, :naive_datetime

    belongs_to :project, Project, type: :binary_id
    has_many :messages, PromptMessage, foreign_key: :conversation_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a new conversation.
  """
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:title, :project_id])
    |> validate_required([:title, :project_id])
    |> foreign_key_constraint(:project_id)
  end

  @doc """
  Updates the conversation title.
  """
  def update_title_changeset(conversation, args) do
    conversation
    |> cast(args, [:title])
    |> validate_required([:title])
    |> validate_length(:title, max: 255)
  end

  @doc """
  """
  def update_period_changeset(conversation, args) do
    conversation
    |> cast(args, [:begin_at, :end_at])
    |> validate_required([:begin_at, :end_at])
  end
end
