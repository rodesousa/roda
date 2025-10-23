defmodule Roda.Questions.Question do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Organizations.Project

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "questions" do
    field :name, :string
    field :prompt, :string

    belongs_to :project, Project, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:name, :prompt, :project_id])
  end
end
