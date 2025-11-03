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

  def add_project(%Scope{} = s, args) do
    args = Map.put(args, "organization_id", s.organization.id)

    case Project.changeset(args) do
      %{valid?: true} = changeset ->
        {:ok, project} = Repo.insert(changeset)

        :telemetry.execute(
          [:roda, :organizations, :group, :created],
          %{count: 1},
          %{
            user_id: s.user.id,
            organization_id: s.organization.id,
            resource_type: "Project",
            resource_id: project.id,
            resource_name: project.name
          }
        )

        {:ok, project}

      changeset ->
        changeset
    end
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

  @doc """
  Counts conversations (testimonies) for a given project.

  ## Example

      iex> count_conversations_by_project(project_id)
      12
  """
  def count_conversations_by_project(project_id, date) do
    Conversation
    |> where([c], c.project_id == ^project_id and c.inserted_at >= ^date)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Lists projects with enriched metrics for an organization.

  Returns projects with additional fields:
  - conversations_count: number of testimonies
  - days_since_creation: days since project creation

  ## Example

      iex> list_projects_with_metrics(scope)
      [%{project: %Project{}, conversations_count: 12, days_since_creation: 5}]
  """
  def list_projects_with_metrics(%Scope{} = s) do
    projects = list_project_by_orga(s)
    one_week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    Enum.map(projects, fn project ->
      conversations_count = count_conversations_by_project(project.id, one_week_ago)
      days_ago = DateTime.diff(DateTime.utc_now(), project.inserted_at, :day)

      %{
        project: project,
        conversations_count: conversations_count,
        days_since_creation: days_ago
      }
    end)
  end

  @doc """
  Calculates global statistics for an organization's projects.

  Returns a map with:
  - active_projects_count: number of active projects
  - total_conversations: total conversations across all projects
  - conversations_this_week: conversations created in the last 7 days

  ## Example

      iex> get_organization_stats(scope)
      %{active_projects_count: 3, total_conversations: 45, conversations_this_week: 12}
  """
  def get_organization_stats(%Scope{} = s) do
    projects = list_project_by_orga(s)
    project_ids = Enum.map(projects, & &1.id)

    one_week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    conversations_this_week =
      Conversation
      |> where([c], c.project_id in ^project_ids and c.inserted_at >= ^one_week_ago)
      |> Repo.aggregate(:count, :id)

    %{
      active_projects_count: length(projects),
      conversations_this_week: conversations_this_week
    }
  end
end
