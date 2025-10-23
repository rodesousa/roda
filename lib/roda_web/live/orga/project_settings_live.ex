defmodule RodaWeb.Orga.ProjectSettingsLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.Conversations
  alias Roda.{Organizations, Questions}

  @tabs ["general", "users"]

  @impl true
  def mount(
        %{"orga_id" => orga_id, "project_id" => project_id},
        _session,
        socket
      ) do
    socket =
      socket
      |> assign(
        project: Organizations.get_project_by_id(project_id),
        organization: Organizations.get_orga_by_id(orga_id)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    tab =
      case Map.get(params, "tab") in @tabs do
        true -> Map.get(params, "tab")
        false -> "general"
      end

    socket =
      assign(socket, tab: tab)

    {:noreply, socket}
  end

  @impl true
  def handle_event("tab", %{"tab" => tab}, socket) do
    tab =
      case tab in @tabs do
        true -> tab
        false -> "general"
      end

    socket =
      assign(socket,
        tab: tab
      )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="settings"
      sidebar_type={:project}
      sidebar_params={%{orga_id: @organization.id, project_id: @project.id}}
    >
      <.page_content>
        <div class="tabs tabs-lift">
          <input
            type="radio"
            name="my_tabs_3"
            class="tab"
            aria-label={gettext("General")}
            phx-click="tab"
            phx-value-tab="general"
            checked={@tab == "general"}
          />
          <div class="tab-content bg-base-100 border-base-300 p-6">
            general
          </div>
          <input
            type="radio"
            name="my_tabs_3"
            class="tab"
            aria-label={gettext("Users")}
            phx-click="tab"
            phx-value-tab="users"
            checked={@tab == "users"}
          />
          <div class="tab-content bg-base-100 border-base-300 p-6">
            users
          </div>
        </div>
      </.page_content>
    </.page>
    """
  end
end
