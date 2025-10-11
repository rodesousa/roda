defmodule Roda.Organization.Project do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Organization.Organization

  schema "projects" do
    field :name, :string

    belongs_to :organization_id, Organization
    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:name])
  end
end
