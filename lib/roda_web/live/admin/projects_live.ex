defmodule RodaWeb.Admin.ProjectsLive do
  use RodaWeb, :live_view
  alias Roda.Organizations
  alias Roda.Organizations.Project

  @impl true
  def mount(%{"orga_id" => orga_id}, _session, socket) do
    socket =
      with {:ok, socket} <- assign_organization(socket, orga_id) do
        socket
        |> assign_project_form()
        |> assign_projects()
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("create_project", %{"project" => params}, socket) do
    ass = socket.assigns
    params = Map.put(params, "organization_id", ass.organization.id)

    socket =
      case Organizations.add_project(params) do
        {:ok, _} ->
          socket
          |> assign_project_form()
          |> assign_projects()
          |> push_event("reset-form", %{})

        {:error, changeset} ->
          socket
          |> assign(project_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-screen-lg mx-auto px-4 py-6">
      <.form
        :let={f}
        id="project-form"
        for={@project_form}
        phx-submit="create_project"
        phx-hook="ResetForm"
      >
        <div class="flex">
          <.input field={f[:name]} label={gettext("Project name")} />
        </div>
        <.button>
          {gettext("Create")}
        </.button>
      </.form>
      <div id="orgas" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-4">
        <%= for  project <- @projects  do %>
          <.card
            name={project.name}
            link={~p"/orgas/#{project.organization_id}/projects/#{project.id}/testify"}
          />
        <% end %>
      </div>
    </div>
    """
  end

  defp assign_project_form(socket) do
    assign(socket, project_form: to_form(Project.changeset(%{})))
  end

  defp assign_projects(socket) do
    ass = socket.assigns
    assign(socket, projects: Organizations.list_project_by_orga_id(ass.organization.id))
  end

  defp assign_organization(socket, orga_id) do
    case Organizations.get_orga_by_id(orga_id) do
      nil -> push_navigate(socket, to: ~p"/admin")
      orga -> {:ok, assign(socket, organization: orga)}
    end
  end
end
