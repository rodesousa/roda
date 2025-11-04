defmodule RodaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use RodaWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1"></div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://cohortes.co" class="btn btn-ghost">{gettext("Website")}</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  import RodaWeb.CoreComponents, only: [icon: 1]
  import RodaWeb.Button, only: [button: 1]

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :scope, :map, default: %{}
  attr :current, :string, default: ""
  slot :inner_block
  slot :extends_sidebar

  def page(assigns) do
    ~H"""
    <div id="sidebar" class="drawer lg:drawer-open">
      <input id="my-drawer-1" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content">
        <button
          phx-click={
            JS.add_class("lg:drawer-open", to: "#sidebar")
            |> JS.set_attribute({"checked", "true"}, to: "#my-drawer-1")
          }
          class="absolute top-4 left-4 btn btn-ghost btn-circle"
        >
          <.icon class="w-5 h-5" name="hero-bars-3-bottom-left" />
        </button>
        {render_slot(@inner_block)}
      </div>
      <div class="drawer-side">
        <label
          for="my-drawer-1"
          aria-label="close sidebar"
          class="drawer-overlay lg:hidden"
        >
        </label>
        <div class="bg-base-200 w-64 flex flex-col min-h-full">
          <button
            phx-click={
              JS.remove_class("lg:drawer-open", to: "#sidebar")
              |> JS.remove_attribute("checked", to: "#my-drawer-1")
            }
            class="absolute top-4 right-4 z-50 btn btn-ghost btn-circle"
          >
            <.icon class="w-5 h-5" name="hero-bars-3-bottom-left" />
          </button>

          <ul class="menu p-4">
            <%= for s <- sidebar_links(@scope) do %>
              <.link navigate={s.link}>
                <li>
                  <button
                    class={[
                      "is-drawer-close:tooltip is-drawer-close:tooltip-right",
                      s.id == @current && "bg-gray-200"
                    ]}
                    data-tip={s.name}
                  >
                    <div class="flex items-center space-x-2">
                      <.icon name={s.icon} class="w-5 h-5" />
                      <div>
                        {s.name}
                      </div>
                    </div>
                  </button>
                </li>
              </.link>
            <% end %>
          </ul>

          <div class="flex-1 w-full overflow-y-auto px-4">
            {render_slot(@extends_sidebar)}
          </div>

          <ul class="menu">
            <li>
              <.button
                :if={@scope.membership && @scope.membership.role == "admin" && @scope.project}
                navigate={~p"/orgas/#{@scope.organization.id}/projects/#{@scope.project.id}/settings"}
                class={[
                  "is-drawer-close:tooltip is-drawer-close:tooltip-right",
                  "group_settings" == @current && "bg-gray-200"
                ]}
              >
                <div class="flex items-center space-x-2">
                  <.icon name="hero-qr-code" class="w-5 h-5" />
                  <div>
                    {gettext("Group Settings")}
                  </div>
                </div>
              </.button>
            </li>

            <li>
              <.button
                :if={@scope.membership && @scope.membership.role == "admin"}
                class={[
                  "is-drawer-close:tooltip is-drawer-close:tooltip-right",
                  "orga_settings" == @current && "bg-gray-200"
                ]}
                navigate={~p"/orgas/#{@scope.organization.id}/settings"}
              >
                <div class="flex items-center space-x-2">
                  <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
                  <div>
                    {gettext("Organization Settings")}
                  </div>
                </div>
              </.button>
            </li>
            <li>
              <.button
                :if={@scope.user}
                navigate={~p"/users/settings"}
                class={[
                  "is-drawer-close:tooltip is-drawer-close:tooltip-right",
                  "user_settings" == @current && "bg-gray-200"
                ]}
              >
                <div class="flex items-center space-x-2">
                  <.icon name="hero-user-circle" class="w-5 h-5" />
                  <div>
                    {gettext("User settings")}
                  </div>
                </div>
              </.button>
            </li>
            <li>
              <.button
                :if={@scope.user}
                href={~p"/users/log-out"}
                method="delete"
                class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
              >
                <div class="flex items-center space-x-2">
                  <.icon name="hero-arrow-left-start-on-rectangle" class="w-5 h-5" />
                  <div>
                    {gettext("Log out")}
                  </div>
                </div>
              </.button>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  slot :inner_block

  def page_content(assigns) do
    ~H"""
    <div class="w-full max-w-screen-lg mx-auto px-4 py-6">
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp sidebar_links(%{organization: nil, project: nil}) do
    [
      %{
        id: "orgas",
        name: gettext("Organizations"),
        link: ~p"/",
        icon: "hero-question-mark-circle"
      }
    ]
  end

  defp sidebar_links(%{project: nil, organization: orga}) do
    [
      %{
        id: "projects",
        name: gettext("Groups"),
        link: ~p"/orgas/#{orga.id}/groups",
        icon: "hero-folder"
      }
    ]
  end

  defp sidebar_links(%{project: project, invite_token: token, organization: nil})
       when not is_nil(project) and not is_nil(token) do
    [
      %{
        id: "testify",
        name: gettext("Testify"),
        link: ~p"/testify/#{token}",
        icon: "hero-microphone"
      },
      %{
        id: "testimonies",
        name: gettext("Testimonies"),
        link: ~p"/testimonies/#{token}",
        icon: "hero-inbox-stack"
      }
    ]
  end

  defp sidebar_links(%{project: project, organization: orga}) do
    [
      %{
        id: "projects",
        name: gettext("Groups"),
        link: ~p"/orgas/#{orga.id}/groups",
        icon: "hero-folder"
      },
      %{
        id: "testify",
        name: gettext("Testify"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/testify",
        icon: "hero-microphone"
      },
      %{
        id: "testimonies",
        name: gettext("Testimonies"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/testimonies",
        icon: "hero-inbox-stack"
      },
      %{
        id: "questions",
        name: gettext("Ask"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/questions",
        icon: "hero-presentation-chart-line"
      },
      %{
        id: "ask",
        name: gettext("Prompt"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/prompt",
        icon: "hero-pencil-square"
      }
      # ,
      # %{
      #   id: "settings",
      #   name: gettext("Settings"),
      #   link: ~p"/orgas/#{orga_id}/projects/#{project_id}/settings",
      #   icon: "hero-question-mark-circle"
      # }
    ]
  end
end
