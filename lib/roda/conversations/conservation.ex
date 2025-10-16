defmodule Roda.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Conversations.Chunk
  alias Roda.Organization.Project

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "conversations" do
    field :fully_transcribed, :boolean, default: false

    has_many :chunks, Chunk
    belongs_to :project, Project, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:project_id])
  end

  def update_changeset(%__MODULE__{} = conversation, attrs) do
    conversation
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:project_id])
  end
end
