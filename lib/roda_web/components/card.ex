defmodule RodaWeb.Card do
  use Phoenix.Component
  use Gettext, backend: RodaWeb.Gettext
  import RodaWeb.Button
  import RodaWeb.CoreComponents, only: [icon: 1]

  attr :name, :string
  attr :link, :string, default: nil

  def card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-md hover:shadow-xl transition-all duration-200 border border-base-300 w-full">
      <div class="card-body p-4">
        <h2 class="card-title text-base break-words overflow-hidden">{@name}</h2>
        <div class="card-actions justify-end mt-2">
          <.link :if={@link} navigate={@link}>
            <.button>
              {gettext("View")}
            </.button>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :project, :map, required: true
  attr :conversations_count, :integer, default: 0
  attr :days_since_creation, :integer, default: 0
  attr :view_link, :string, required: true
  attr :share_link, :string, default: nil

  def project_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-md hover:shadow-2xl transition-all duration-300 border border-base-300 w-full">
      <div class="card-body p-5">
        <!-- Header with status badge -->
        <div class="flex justify-between items-start">
          <h2 class="card-title text-lg break-words flex-1 pr-2">{@project.name}</h2>
        </div>

        <div class="flex flex-col gap-2 mt-2 text-sm text-base-content/70">
          <div class="flex items-center gap-2">
            <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
            <span>
              {@conversations_count} {if @conversations_count <= 1,
                do: gettext("testimony last week"),
                else: gettext("testimonies last week")}
            </span>
          </div>
        </div>

        <div class="card-actions justify-end mt-4 gap-2">
          <.link navigate={@view_link}>
            <button class="btn btn-primary btn-sm gap-1">
              <.icon name="hero-microphone" class="w-4 h-4" />
              {gettext("Testify")}
            </button>
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
