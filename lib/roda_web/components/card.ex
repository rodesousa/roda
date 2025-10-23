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

  attr :icon, :string
  slot :inner_block

  def icon_card(assigns) do
    ~H"""
    <div class="p-4 rounded-lg shadow-md cursor-pointer transition-all duration-200 hover:shadow-lg border-2 border-dashed border-gray-300 bg-white h-32 flex flex-col items-center justify-center group">
      <div class="flex items-center justify-center mb-2">
        <.icon name={@icon} class="text-cohortes-black h-6 w-6 group-hover:text-cohortes-red" />
      </div>
      <h3 class="text-lg font-semibold text-cohortes-black group-hover:text-cohortes-red transition-colors text-center">
        {render_slot(@inner_block)}
      </h3>
    </div>
    """
  end
end
