defmodule Roda.Project.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :memgraph_chunk_capacity, :integer
    field :memgraph_entity_capacity, :integer
    timestamps(type: :utc_datetime)
  end

  def init_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:name, :memgraph_chunk_capacity, :memgraph_chunk_capacity])
  end

  def name_changeset(%__MODULE__{} = project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
