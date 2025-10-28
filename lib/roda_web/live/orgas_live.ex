defmodule RodaWeb.OrgasLive do
  @moduledoc """
  """
  use RodaWeb, :live_view
  alias Roda.Organizations

  @impl true
  def mount(_, _session, socket) do
    ass = socket.assigns
    members = Organizations.list_organisation_by_user(ass.current_scope)
    socket = assign(socket, members: members)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.page
      current="orgas"
      sidebar_type={:user}
    >
      <.page_content>
        <div id="orgas" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for  member <- @members  do %>
            <.card
              name={member.organization.name}
              link={~p"/orgas/#{member.organization.id}/projects"}
            />
          <% end %>
        </div>
      </.page_content>
    </.page>
    """
  end
end
