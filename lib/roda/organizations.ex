defmodule Roda.Organizations do
  import Ecto.Query
  alias Roda.{Repo, Accounts}
  alias Roda.Organizations.{Project, Organization, OrganizationMembership}
  alias Roda.Conversations.Conversation
  alias Roda.Accounts.Scope
  alias Roda.LLM.Provider

  @doc """
  Gets an organization and the user's membership in it.

  Returns `{:ok, organization, membership}` if the user is a member,
  `{:error, :not_found}` otherwise.
  """
  def get_user_membership(user_id, organization_id) do
    query =
      OrganizationMembership
      |> where([m], m.user_id == ^user_id and m.organization_id == ^organization_id)
      |> preload([:organization])

    case Repo.one(query) do
      %OrganizationMembership{organization: org} = membership ->
        {:ok, org, membership}

      nil ->
        {:error, :not_found}
    end
  end

  def get_membership_by_organization(%Scope{} = s) do
    OrganizationMembership
    |> where([m], m.organization_id == ^s.organization.id)
    |> preload([:user])
    |> Repo.all()
  end

  def add_organization(args) do
    Organization.changeset(args)
    |> Repo.insert()
  end

  def add_organization!(args) do
    Organization.changeset(args)
    |> Repo.insert!()
  end

  def add_project(args \\ %{}) do
    Project.changeset(args)
    |> Repo.insert()
  end

  def add_project(%Scope{} = _s, project_args) do
    Project.changeset(project_args)
    |> Repo.insert()
  end

  def list_project_by_orga_id(orga_id) do
    Project
    |> where([p], p.organization_id == ^orga_id and p.is_active == true)
    |> Repo.all()
  end

  def get_conversations(project_id) do
    Conversation
    |> where([c], c.project_id == ^project_id)
    |> preload([:chunks])
    |> Repo.all()
  end

  def get_conversations(%Scope{} = s, %NaiveDateTime{} = begin_at, %NaiveDateTime{} = end_at) do
    Conversation
    |> where(
      [c],
      c.project_id == ^s.project.id and c.inserted_at >= ^begin_at and c.inserted_at <= ^end_at
    )
    |> preload([:chunks])
    |> Repo.all()
  end

  def list_orgas() do
    Organization
    |> where([o], o.is_active == true)
    |> Repo.all()
  end

  def get_orga_by_id(orga_id) do
    Organization
    |> where([o], o.id == ^orga_id and o.is_active == true)
    |> select([:name, :id])
    |> Repo.one()
  end

  def get_project_by_id(project_id) do
    Project
    |> where([o], o.id == ^project_id and o.is_active == true)
    |> select([:name, :id])
    |> Repo.one()
  end

  @doc """
  Adds a user to an organization with a specific role.
  """
  def add_member(%Scope{} = s, user_id, role) do
    %OrganizationMembership{}
    |> OrganizationMembership.changeset(%{
      organization_id: s.organization.id,
      user_id: user_id,
      role: role
    })
    |> Repo.insert()
  end

  def register_user_and_invite(%Scope{} = s, user_attrs) do
    case Accounts.register_user(user_attrs) do
      {:ok, user} ->
        {:ok, member} = add_member(s, user.id, "invite")
        {:ok, %{user: user, member: member}}

      {_, changeset} ->
        {:error, changeset}
    end
  end

  def add_provider(%Scope{} = s, args) do
    args
    |> Map.put(:organization_id, s.organization.id)
    |> Provider.changeset()
    |> Repo.insert()
  end

  def list_organisation_by_user(%Scope{} = s) do
    OrganizationMembership
    |> where([m], m.user_id == ^s.user.id)
    |> preload([:organization])
    |> Repo.all()
  end

  def list_project_by_orga(%Scope{} = s) do
    Project
    |> where([p], p.organization_id == ^s.organization.id and p.is_active == true)
    |> Repo.all()
  end

  def get_provider_by_organization(%Scope{} = scope, provider_type \\ "chat") do
    Provider
    |> where(
      [p],
      p.organization_id == ^scope.organization.id and p.is_active == true and
        p.type == ^provider_type
    )
    |> Repo.one()
  end

  def list_project_by_orga(%Scope{} = s) do
    Project
    |> where([p], p.organization_id == ^s.organization.id and p.is_active == true)
    |> Repo.all()
  end

  def get_project(orga_id, project_id) do
    Project
    |> where([p], p.id == ^project_id and p.organization_id == ^orga_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      project -> {:ok, project}
    end
  end
end
