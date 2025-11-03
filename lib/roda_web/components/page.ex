defmodule RodaWeb.Page do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use Gettext, backend: RodaWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: RodaWeb.Endpoint,
    router: RodaWeb.Router,
    statics: RodaWeb.static_paths()

  import RodaWeb.CoreComponents, only: [icon: 1]
  import RodaWeb.Button, only: [button: 1]

  slot :inner_block
  attr :scope, :map, default: %{}
  attr :current, :string, default: ""
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
                class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
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
                  "is-drawer-close:tooltip is-drawer-close:tooltip-right"
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
                class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
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
