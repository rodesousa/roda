defmodule RodaWeb.Orga.ProjectSettingsLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.{Conversations, Invite}
  alias Roda.{Organizations, Questions}

  @tabs ["invite", "users"]

  @impl true
  def mount(_, _session, socket) do
    socket =
      socket
      |> assign_invitation_link()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    tab =
      case Map.get(params, "tab") in @tabs do
        true -> Map.get(params, "tab")
        false -> "invite"
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
      scope={@current_scope}
    >
      <.page_content>
        <div class="tabs tabs-lift">
          <input
            type="radio"
            name="my_tabs_3"
            class="tab"
            aria-label={gettext("Invite")}
            phx-click="tab"
            phx-value-tab="invite"
            checked={@tab == "invite"}
          />
          <div class="tab-content bg-base-100 border-base-300 p-6">
            <div>
              {get_qrcode(url(~p"/testify/#{@token}"))}
            </div>

            <.button phx-click={
              JS.dispatch("phx:clipcopy", detail: %{id: url(~p"/testify/#{@token}")})
            }>
              {gettext("Copy url")}
            </.button>
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

  def get_qrcode(url) do
    url
    |> EQRCode.encode()
    |> EQRCode.svg()
    |> Floki.parse_document!()
    |> Floki.find("svg")
    |> Floki.raw_html()
    |> raw()
  end

  defp assign_invitation_link(socket) do
    %{current_scope: scope} = socket.assigns

    token =
      case Invite.get_projet_token_by_project(scope) do
        {:ok, token} -> token
        _ -> Invite.generate_project_token(scope)
      end

    socket
    |> assign(token: token)
  end
end
