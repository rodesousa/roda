defmodule RodaWeb.Orga.ProjectsLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.{Organizations}

  @impl true
  def mount(_p, _session, socket) do
    socket =
      socket
      |> assign_projects()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="projects"
      scope={@current_scope}
    >
      <.page_content>
        <div id="projects" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-4">
          <%= for p <- @projects do %>
            <.card
              link={~p"/orgas/#{@current_scope.organization.id}/projects/#{p.id}/testify"}
              name={p.name}
            />
          <% end %>
        </div>
      </.page_content>
    </.page>
    """
  end

  defp assign_projects(socket) do
    ass = socket.assigns
    projects = Organizations.list_project_by_orga(ass.current_scope)

    assign(socket, projects: projects)
  end
end
