defmodule Roda.Organizations.Project do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: RodaWeb.Gettext

  alias Roda.{Repo, Organizations.Organization}

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "projects" do
    field :name, :string
    field :is_active, :boolean, default: true

    belongs_to :organization, Organization, type: :binary_id
    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = p, attrs) do
    p
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:name, :organization_id])
    |> validate_length(:name, min: 1, max: 255)
    |> unsafe_validate_unique([:name, :organization_id], Repo,
      message: gettext("A group with this name already exists in this organization")
    )
    |> unique_constraint(:name,
      name: :projects_organization_id_name_index,
      message: gettext("A group with this name already exists in this organization")
    )
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:name, :organization_id])
    |> validate_length(:name, min: 1, max: 255)
    |> unsafe_validate_unique([:name, :organization_id], Repo,
      message: gettext("A group with this name already exists in this organization")
    )
    |> unique_constraint(:name,
      name: :projects_organization_id_name_index,
      message: gettext("A group with this name already exists in this organization")
    )
  end
end
