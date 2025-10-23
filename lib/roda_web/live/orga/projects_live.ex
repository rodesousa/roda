defmodule RodaWeb.Orga.ProjectsLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.{Conversations, Date}
  alias Roda.{Organizations, Questions}

  @impl true
  def mount(
        %{"orga_id" => orga_id},
        _session,
        socket
      ) do
    socket =
      socket
      |> assign(organization: Organizations.get_orga_by_id(orga_id))
      |> assign_projects()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="projects"
      sidebar_type={:organization}
      sidebar_params={%{orga_id: @organization.id}}
    >
      <.page_content>
      <div id="projects" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-4">
          <%= for p <- @projects do %>
            <.card link={~p"/orgas/#{@organization.id}/projects/#{p.id}/testify"} name={p.name} />
          <% end %>
        </div>
      </.page_content>
    </.page>
    """
  end

  defp assign_projects(socket) do
    ass = socket.assigns
    projects = Organizations.list_project_by_orga_id(ass.organization.id)

    assign(socket, projects: projects)
  end
end
