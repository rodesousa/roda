defmodule Roda.Organizations do
  @moduledoc """
  Technical debt:
  - Each functions using Conversation have to mentionned if active and fully_transcribed is used and why
  """

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

  ## Example

      iex> get_user_membership(user_id, org_id)
      {:ok, %Organization{}, %OrganizationMembership{}}
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

  @doc """
  Lists all memberships for a given organization.

  Returns a list of organization memberships with preloaded users.

  ## Example

      iex> get_membership_by_organization(scope)
      [%OrganizationMembership{user: %User{}}, ...]
  """
  def get_membership_by_organization(%Scope{} = s) do
    OrganizationMembership
    |> where([m], m.organization_id == ^s.organization.id)
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Creates a new project within an organization scope.

  Automatically associates the project with the organization from the scope
  and emits telemetry events upon successful creation.

  ## Example

      iex> add_project(scope, %{"name" => "My Project"})
      {:ok, %Project{}}
  """
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

  @doc """
  Creates a new organization.

  Returns `{:ok, organization}` on success or an error changeset on failure.

  ## Example

      iex> add_organization(%{"name" => "Acme Corp"})
      {:ok, %Organization{}}
  """
  def add_organization(args) do
    Organization.changeset(args)
    |> Repo.insert()
  end

  @doc """
  Creates a new organization, raising an error on failure.

  Returns the organization or raises an exception if validation fails.

  ## Example

      iex> add_organization!(%{"name" => "Acme Corp"})
      %Organization{}
  """
  def add_organization!(args) do
    Organization.changeset(args)
    |> Repo.insert!()
  end

  @doc """
  Creates a new project without organization scope.

  Returns `{:ok, project}` on success or an error changeset on failure.

  ## Example

      iex> add_project(%{"name" => "Project X", "organization_id" => org_id})
      {:ok, %Project{}}
  """
  def add_project(args \\ %{}) do
    Project.changeset(args)
    |> Repo.insert()
  end

  @doc """
  Lists all active projects for a given organization ID.

  Returns a list of active projects belonging to the specified organization.

  ## Example

      iex> list_project_by_orga_id(org_id)
      [%Project{}, ...]
  """
  def list_project_by_orga_id(orga_id) do
    Project
    |> where([p], p.organization_id == ^orga_id and p.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets all conversations for a given project.

  Returns conversations with preloaded chunks.

  ## Example

      iex> get_conversations(project_id)
      [%Conversation{chunks: [...]}, ...]
  """
  def get_conversations(project_id) do
    Conversation
    |> where([c], c.project_id == ^project_id)
    |> preload([:chunks])
    |> Repo.all()
  end

  @doc """
  Gets conversations for a project within a date range.

  Returns only active and fully transcribed conversations between the specified dates,
  with preloaded chunks.

  ## Example

      iex> get_conversations(scope, ~N[2025-01-01 00:00:00], ~N[2025-01-31 23:59:59])
      [%Conversation{chunks: [...]}, ...]
  """
  def get_conversations(%Scope{} = s, %NaiveDateTime{} = begin_at, %NaiveDateTime{} = end_at) do
    Conversation
    |> where(
      [c],
      c.project_id == ^s.project.id and c.inserted_at >= ^begin_at and c.inserted_at <= ^end_at and
        c.active == true and
        c.fully_transcribed == true
    )
    |> preload([:chunks])
    |> Repo.all()
  end

  @doc """
  Gets conversation IDs for a project within a date range.

  Returns only IDs of active and fully transcribed conversations between the specified dates.

  ## Example

      iex> get_conversation_ids(scope, ~N[2025-01-01 00:00:00], ~N[2025-01-31 23:59:59])
      [1, 2, 3, ...]
  """
  def get_conversation_ids(%Scope{} = s, %NaiveDateTime{} = begin_at, %NaiveDateTime{} = end_at) do
    Conversation
    |> where(
      [c],
      c.project_id == ^s.project.id and c.inserted_at >= ^begin_at and c.inserted_at <= ^end_at and
        c.active == true and
        c.fully_transcribed == true
    )
    |> select([s], s.id)
    |> Repo.all()
  end

  @doc """
  Lists all active organizations.

  Returns a list of all organizations where `is_active` is true.

  ## Example

      iex> list_orgas()
      [%Organization{}, ...]
  """
  def list_orgas() do
    Organization
    |> where([o], o.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets an organization by ID.

  Returns only the name and id fields of the active organization.

  ## Example

      iex> get_orga_by_id(org_id)
      %Organization{name: "Acme Corp", id: 1}
  """
  def get_orga_by_id(orga_id) do
    Organization
    |> where([o], o.id == ^orga_id and o.is_active == true)
    |> select([:name, :id])
    |> Repo.one()
  end

  @doc """
  Gets a project by ID.

  Returns only the name and id fields of the active project.

  ## Example

      iex> get_project_by_id(project_id)
      %Project{name: "My Project", id: 1}
  """
  def get_project_by_id(project_id) do
    Project
    |> where([o], o.id == ^project_id and o.is_active == true)
    |> select([:name, :id])
    |> Repo.one()
  end

  @doc """
  Adds a user to an organization with a specific role.

  Creates a new organization membership linking the user to the organization
  with the specified role.

  ## Example

      iex> add_member(scope, user_id, "admin")
      {:ok, %OrganizationMembership{}}
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

  @doc """
  Registers a new user and adds them to an organization.

  Creates a new user account and automatically adds them as a member
  of the organization with the role specified in user attributes.

  ## Example

      iex> register_user(scope, %{"email" => "user@example.com", "password" => "secret", "role" => "user"})
      {:ok, %{user: %User{}, member: %OrganizationMembership{}}}
  """
  def register_user(%Scope{} = s, user_attrs) do
    case Accounts.register_user_email_password(user_attrs) do
      {:ok, user} ->
        {:ok, member} = add_member(s, user.id, user_attrs["role"])
        {:ok, %{user: user, member: member}}

      changeset ->
        changeset
    end
  end

  @doc """
  Adds an LLM provider to an organization.

  Creates a new provider (e.g., OpenAI, Anthropic) configuration
  for the organization.

  ## Example

      iex> add_provider(scope, %{type: "chat", name: "OpenAI"})
      {:ok, %Provider{}}
  """
  def add_provider(%Scope{} = s, args) do
    args
    |> Map.put(:organization_id, s.organization.id)
    |> Provider.changeset()
    |> Repo.insert()
  end

  @doc """
  Lists all organizations for a given user.

  Returns organization memberships with preloaded organization data
  for all organizations the user belongs to.

  ## Example

      iex> list_organisation_by_user(scope)
      [%OrganizationMembership{organization: %Organization{}}, ...]
  """
  def list_organisation_by_user(%Scope{} = s) do
    OrganizationMembership
    |> where([m], m.user_id == ^s.user.id)
    |> preload([:organization])
    |> Repo.all()
  end

  @doc """
  Lists all active projects for an organization from scope.

  Returns all active projects belonging to the organization in the current scope.

  ## Example

      iex> list_project_by_orga(scope)
      [%Project{}, ...]
  """
  def list_project_by_orga(%Scope{} = s) do
    Project
    |> where([p], p.organization_id == ^s.organization.id and p.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets an active provider for an organization by type.

  Returns the active provider configuration for the specified type
  (default: "chat").

  ## Example

      iex> get_provider_by_organization(scope, "chat")
      %Provider{type: "chat"}
  """
  def get_provider_by_organization(%Scope{} = scope, provider_type \\ "chat") do
    Provider
    |> where(
      [p],
      p.organization_id == ^scope.organization.id and p.is_active == true and
        p.type == ^provider_type
    )
    |> Repo.one()
  end

  @doc """
  Gets a project by organization and project IDs.

  Returns `{:ok, project}` if found, `{:error, :not_found}` otherwise.

  ## Example

      iex> get_project(org_id, project_id)
      {:ok, %Project{}}
  """
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
    |> where(
      [c],
      c.project_id == ^project_id and c.inserted_at >= ^date and
        c.active == true and
        c.fully_transcribed == true
    )
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
      |> where(
        [c],
        c.project_id in ^project_ids and c.inserted_at >= ^one_week_ago and c.active == true and
          c.fully_transcribed == true
      )
      |> Repo.aggregate(:count, :id)

    %{
      active_projects_count: length(projects),
      conversations_this_week: conversations_this_week
    }
  end

  @doc """
  Updates the role of a user's organization membership.

  Finds the organization membership for the given user and updates their role.
  Returns `{:error, :not_found}` if no membership exists.

  ## Example

      iex> set_membership_role(user_id, "admin")
      {:ok, %OrganizationMembership{role: "admin"}}
  """
  def set_membership_role(user_id, role) do
    OrganizationMembership
    |> where([q], q.user_id == ^user_id)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      member ->
        OrganizationMembership.changeset(member, %{role: role})
        |> Repo.update()
    end
  end

  @doc """
  Updates the name of an organization.

  Only users with "admin" role can update the organization name.
  Returns `{:error, :not_authorized}` if the user is not an admin.

  ## Example

      iex> set_organization_name(scope, %{"name" => "New Corp Name"})
      {:ok, %Organization{name: "New Corp Name"}}
  """
  def set_organization_name(%Scope{} = s, args) do
    if s.membership.role == "admin" do
      case Organization.changeset(s.organization, args) do
        %{valid?: true} = changeset ->
          Repo.update(changeset)

        changeset ->
          changeset
      end
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Updates the name of a project.

  Only users with "admin" role can update the project name.
  Returns `{:error, :not_authorized}` if the user is not an admin.

  ## Example

      iex> set_project_name(scope, %{"name" => "New Project Name"})
      {:ok, %Project{name: "New Project Name"}}
  """
  def set_project_name(%Scope{} = s, args) do
    if s.membership.role == "admin" do
      case Project.changeset(s.project, args) do
        %{valid?: true} = changeset ->
          Repo.update(changeset)

        changeset ->
          changeset
      end
    else
      {:error, :not_authorized}
    end
  end
end
