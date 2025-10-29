defmodule Roda.Organizations.OrganizationMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}

  @roles ~w(admin manager member invite)

  schema "organization_memberships" do
    belongs_to :user, Roda.Accounts.User
    belongs_to :organization, Roda.Organizations.Organization, type: Uniq.UUID
    field :role, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the list of valid roles.
  """
  def roles, do: @roles

  @doc """
  Creates a changeset for an organization membership.
  """
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :organization_id, :role])
    |> validate_required([:user_id, :organization_id, :role])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:user_id, :organization_id])
  end
end
