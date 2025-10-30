defmodule RodaWeb.Dropdown do
  use Phoenix.Component
  use Gettext, backend: RodaWeb.Gettext

  attr :name, :string
  slot :items

  def dropdown(assigns) do
    ~H"""
    <details class="dropdown">
      <summary class="btn m-1">{@name}</summary>
      <ul class="menu dropdown-content bg-base-100 rounded-box z-1 w-52 p-2 shadow-sm">
        {render_slot(@items)}
      </ul>
    </details>
    """
  end
end
