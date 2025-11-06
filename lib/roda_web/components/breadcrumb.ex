defmodule RodaWeb.Breadcrumb do
  use Phoenix.Component
  import RodaWeb.CoreComponents, only: [icon: 1]
  use Gettext, backend: RodaWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: RodaWeb.Endpoint,
    router: RodaWeb.Router,
    statics: RodaWeb.static_paths()

  attr :scope, :any
  attr :i, :string, required: true
  slot :others

  def breadcrumb(assigns) do
    ~H"""
    <div class="breadcrumbs text-sm mb-6 mt-6 lg:mt-0">
      <ul>
        <li>
          <.link navigate={~p"/orgas/#{@scope.organization.id}/groups"}>
            <.icon name="hero-folder" class="w-5 h-5" />
            {@scope.organization.name}
          </.link>
        </li>
        <li :if={@scope.project}>
          <.link navigate={~p"/orgas/#{@scope.organization.id}/projects/#{@scope.project.id}/testify"}>
            <.icon name="hero-folder" class="w-5 h-5" />
            {@scope.project.name}
          </.link>
        </li>
        {render_slot(@others)}
        <li>
          <span class="font-semibold">{@i}</span>
        </li>
      </ul>
    </div>
    """
  end
end
