defmodule RodaWeb.Orga.GroupsLive do
  @moduledoc """
  """
  use RodaWeb, :live_view

  alias Roda.{Organizations}
  alias Roda.Organizations.Project

  @impl true
  def mount(_p, _session, socket) do
    socket =
      socket
      |> assign_projects_with_metrics()
      |> assign_organization_stats()
      |> assign_group_form()

    {:ok, socket}
  end

  def assign_group_form(socket) do
    socket
    |> assign(group_form: to_form(Project.changeset(%{})))
  end

  @impl true
  def handle_event("group:creation", params, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      with true <- scope.membership.role == "admin" do
        case Organizations.add_project(scope, params["project"]) do
          {:ok, _} ->
            socket
            |> assign_projects_with_metrics()
            |> assign_organization_stats()
            |> assign_group_form()
            |> push_event("close:modal", %{id: "group-creation"})

          changeset ->
            socket
            |> assign(group_form: to_form(Map.put(changeset, :action, :validate)))
        end
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.modal id="group-creation">
      <.group_creation form={@group_form} />
    </.modal>
    <.page current="projects" scope={@current_scope}>
      <.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Groups")} />

        <div class="stats stats-vertical sm:stats-horizontal shadow w-full mb-6">
          <div class="stat">
            <div class="stat-figure text-primary">
              <.icon name="hero-folder" class="w-8 h-8" />
            </div>
            <div class="stat-title">{gettext("Active Groups")}</div>
            <div :if={not @stats.ok?} class="stat-value">
              <span class="loading loading-spinner loading-md text-primary"></span>
            </div>
            <div :if={@stats.ok?} class="stat-value text-primary">
              {@stats.result.active_projects_count}
            </div>
          </div>

          <div class="stat">
            <div class="stat-figure text-accent">
              <.icon name="hero-chart-bar" class="w-8 h-8" />
            </div>
            <div class="stat-title">{gettext("This Week")}</div>
            <div :if={not @stats.ok?} class="stat-value">
              <span class="loading loading-spinner loading-md text-accent"></span>
            </div>
            <div :if={@stats.ok?} class="stat-value text-accent">
              {@stats.result.conversations_this_week}
            </div>
            <div class="stat-desc">{gettext("New testimonies")}</div>
          </div>
        </div>
        <!-- Header with context and CTA -->
        <div class="mb-6">
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-3">
              <h1 class="text-3xl font-bold">{gettext("Groups")}</h1>
            </div>
            <button
              :if={@current_scope.membership.role == "admin"}
              id="modal-group-button"
              phx-click={show_modal("group-creation")}
              class="btn btn-primary gap-2"
            >
              <.icon name="hero-plus" />
              {gettext("New Group")}
            </button>
          </div>
          <p class="text-base-content/70">
            {gettext(
              "Groups are spaces where you collect and organize testimonies from your community."
            )}
          </p>
        </div>
        <!-- Groups Grid or Empty State -->
        <%= if @projects_with_metrics == [] do %>
          <!-- Empty State -->
          <div class="hero min-h-[50vh] bg-base-200 rounded-box">
            <div class="hero-content text-center">
              <div class="max-w-md">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1"
                  stroke="currentColor"
                  class="w-24 h-24 mx-auto text-base-content/30 mb-6"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M3.75 9.776c.112-.017.227-.026.344-.026h15.812c.117 0 .232.009.344.026m-16.5 0a2.25 2.25 0 00-1.883 2.542l.857 6a2.25 2.25 0 002.227 1.932H19.05a2.25 2.25 0 002.227-1.932l.857-6a2.25 2.25 0 00-1.883-2.542m-16.5 0V6A2.25 2.25 0 016 3.75h3.879a1.5 1.5 0 011.06.44l2.122 2.12a1.5 1.5 0 001.06.44H18A2.25 2.25 0 0120.25 9v.776"
                  />
                </svg>
                <h2 class="text-2xl font-bold mb-4">
                  {gettext("No groups yet")}
                </h2>
                <p class="text-base-content/70 mb-6">
                  {gettext(
                    "Create your first project to start collecting testimonies from your community. Each project can have its own questions and settings."
                  )}
                </p>
                <p class="text-sm text-base-content/60 italic mb-8">
                  {gettext(
                    "💡 Tip: Groups help you organize testimonies by theme, campaign, or time period."
                  )}
                </p>
                <button
                  phx-click="new_project"
                  class="btn btn-primary btn-lg gap-2"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="2"
                    stroke="currentColor"
                    class="w-6 h-6"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                  </svg>
                  {gettext("Create my first group")}
                </button>
              </div>
            </div>
          </div>
        <% else %>
          <!-- Groups Grid -->
          <div
            id="projects"
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6"
          >
            <%= for project_data <- @projects_with_metrics do %>
              <.project_card
                project={project_data.project}
                conversations_count={project_data.conversations_count}
                days_since_creation={project_data.days_since_creation}
                view_link={
                  ~p"/orgas/#{@current_scope.organization.id}/projects/#{project_data.project.id}/testify"
                }
              />
            <% end %>
          </div>
        <% end %>
      </.page_content>
    </.page>
    """
  end

  defp group_creation(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="text-xl font-bold">{gettext("Create new group")}</h2>

      <p class="text-sm text-base-content/70">
        {gettext("Groups help you organize and track testimonies from specific communities.")}
      </p>

      <.form id="group-form" for={@form} phx-submit="group:creation" class="space-y-4">
        <.input
          field={@form[:name]}
          label={gettext("Group name")}
          placeholder={gettext("e.g., Marketing Team 2024")}
          required={true}
        />

        <div class="flex justify-end gap-2 pt-4">
          <.button phx-click={hide_modal("group-creation")} type="button" class="btn btn-ghost">
            {gettext("Cancel")}
          </.button>
          <.button type="submit" class="btn btn-primary">
            {gettext("Create group")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  defp assign_projects_with_metrics(socket) do
    %{current_scope: scope} = socket.assigns
    assign(socket, projects_with_metrics: Organizations.list_projects_with_metrics(scope))
  end

  defp assign_organization_stats(socket) do
    %{current_scope: scope} = socket.assigns

    socket
    |> assign_async(:stats, fn ->
      stats = Organizations.get_organization_stats(scope)
      {:ok, %{stats: stats}}
    end)
  end
end
