defmodule RodaWeb.Admin.OrgasLive do
  use RodaWeb, :live_view
  alias Roda.Organizations

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_orga_form()
      |> assign_orgas()

    {:ok, socket}
  end

  @impl true
  def handle_event("create_orga", %{"orga" => params}, socket) do
    socket =
      case Organizations.add_organization!(params) do
        {:ok, orga} ->
          push_navigate(socket, to: ~p"/admin/orgas/#{orga.id}")
          socket

        {:error, changeset} ->
          socket
          |> assign(orga_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-screen-lg mx-auto px-4 py-6">
      <.form :let={f} for={@orga_form} phx-submit="create_orga">
        <div class="flex">
          <.input field={f[:name]} label={gettext("Organization name")} />
        </div>
        <.button>
          {gettext("Create")}
        </.button>
      </.form>

      <div id="orgas" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-4">
        <%= for  orga <- @orgas  do %>
          <.card name={orga.name} link={~p"/admin/orgas/#{orga.id}"} />
        <% end %>
      </div>
    </div>
    """
  end

  defp assign_orga_form(socket) do
    assign(socket, orga_form: to_form(%{name: ""}, as: "orga"))
  end

  defp assign_orgas(socket) do
    assign(socket, orgas: Organizations.list_orgas())
  end
end
