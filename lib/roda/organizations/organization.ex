defmodule Roda.Organizations.Organization do
  @moduledoc """
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}

  schema "organizations" do
    field :name, :string
    field :is_active, :boolean, default: true

    many_to_many :users, Roda.Accounts.User,
      join_through: Roda.Organizations.OrganizationMembership

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = orga, attrs) do
    orga
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
