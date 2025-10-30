defmodule RodaWeb.Page do
  use Phoenix.Component
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

  def page(assigns) do
    ~H"""
    <div class="drawer drawer-open">
      <input id="my-drawer-4" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content">
        {render_slot(@inner_block)}
      </div>

      <div class="drawer-side is-drawer-close:overflow-visible">
        <label for="my-drawer-4" aria-label="close sidebar" class="drawer-overlay"></label>
        <div class="is-drawer-close:w-14 is-drawer-open:w-64 bg-base-200 flex flex-col items-start min-h-full">
          <!-- Sidebar content here -->
          <ul class="menu w-full grow">
            <!-- list item -->
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
                    <.icon name={s.icon} />
                    <span class="is-drawer-close:hidden">{s.name}</span>
                  </button>
                </li>
              </.link>
            <% end %>
          </ul>

          <div class="my-2 mx-4 flex flex-col space-y-2">
            <.button
              :if={@scope.membership && @scope.membership.role == "admin" && @scope.project}
              navigate={~p"/orgas/#{@scope.organization.id}/projects/#{@scope.project.id}/settings"}
              class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
            >
              <.icon name="hero-cog-6-tooth" />
              <span class="is-drawer-close:hidden">{gettext("Project Settings")}</span>
            </.button>

            <.button
              :if={@scope.membership && @scope.membership.role == "admin"}
              navigate={~p"/orgas/#{@scope.organization.id}/settings"}
              class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
            >
              <.icon name="hero-cog-6-tooth" />
              <span class="is-drawer-close:hidden">{gettext("Organization Settings")}</span>
            </.button>
            <.button
              :if={@scope.user}
              navigate={~p"/users/settings"}
              class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
            >
              <.icon name="hero-cog-6-tooth" />
              <span class="is-drawer-close:hidden">{gettext("User settings")}</span>
            </.button>
            <.button
              :if={@scope.user}
              href={~p"/users/log-out"}
              method="delete"
              class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
            >
              <.icon name="hero-arrow-left-start-on-rectangle" />
              <span class="is-drawer-close:hidden">{gettext("Log out")}</span>
            </.button>
          </div>

          <div class="m-2 is-drawer-close:tooltip is-drawer-close:tooltip-right" data-tip="Open">
            <label
              for="my-drawer-4"
              class="btn btn-ghost btn-circle drawer-button is-drawer-open:rotate-y-180"
            >
              <.icon name="sidebar" />
            </label>
          </div>
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
        name: gettext("Projects"),
        link: ~p"/orgas/#{orga.id}/projects",
        icon: "hero-question-mark-circle"
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
        icon: "hero-question-mark-circle"
      },
      %{
        id: "testimonies",
        name: gettext("Testimonies"),
        link: ~p"/testimonies/#{token}",
        icon: "hero-question-mark-circle"
      }
    ]
  end

  defp sidebar_links(%{project: project, organization: orga}) do
    [
      %{
        id: "projects",
        name: gettext("Projects"),
        link: ~p"/orgas/#{orga.id}/projects",
        icon: "hero-question-mark-circle"
      },
      %{
        id: "testify",
        name: gettext("Testify"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/testify",
        icon: "hero-question-mark-circle"
      },
      %{
        id: "testimonies",
        name: gettext("Testimonies"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/testimonies",
        icon: "hero-question-mark-circle"
      },
      %{
        id: "questions",
        name: gettext("Ask"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/questions",
        icon: "hero-question-mark-circle"
      },
      %{
        id: "ask",
        name: gettext("Prompt"),
        link: ~p"/orgas/#{orga.id}/projects/#{project.id}/ask",
        icon: "hero-question-mark-circle"
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
