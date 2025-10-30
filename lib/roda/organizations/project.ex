defmodule Roda.Organizations.Project do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Organizations.Organization

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "projects" do
    field :name, :string
    field :is_active, :boolean, default: true

    belongs_to :organization, Organization, type: :binary_id
    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:name, :organization_id])
  end
end
