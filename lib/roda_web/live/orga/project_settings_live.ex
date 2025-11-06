defmodule RodaWeb.Orga.ProjectSettingsLive do
  @moduledoc """
  Miss:
  - Cannot rename
  - Cannot delete
  - Cannot archive
  - When an user change the lang, he needs to reload the page
  """
  use RodaWeb, :live_view

  alias Roda.Invite

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
  def handle_event("copy_link", _, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Invitation link copied to clipboard"))

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
    <RodaWeb.Layouts.page
      flash={@flash}
      current="group_settings"
      scope={@current_scope}
    >
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Group Settings")} />
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
            <div class="alert mb-6">
              <div class="flex flex-col gap-2">
                <p>
                  {gettext(
                    "Share this invitation link or QR code to allow participants to submit testimonies to this project."
                  )}
                </p>
                <div class="text-sm space-y-1">
                  <p>
                    <strong>{gettext("QR Code:")}</strong>
                    {" "}
                    {gettext("Scan with a mobile device to quickly access the testimony form.")}
                  </p>
                  <p>
                    <strong>{gettext("Link:")}</strong>
                    {" "}
                    {gettext("Copy and share the direct URL via email, messaging, or social media.")}
                  </p>
                </div>
              </div>
            </div>

            <div class="space-y-6">
              <div class="card bg-base-200 shadow-sm">
                <div class="card-body items-center">
                  <h3 class="card-title text-base mb-2">{gettext("QR Code")}</h3>
                  <div class="p-4 bg-white rounded-lg">
                    {get_qrcode(url(~p"/testify/#{@token}"))}
                  </div>
                  <p class="text-sm text-base-content/70 text-center mt-2">
                    {gettext("Scan this code to access the testimony form")}
                  </p>
                </div>
              </div>

              <div class="card bg-base-200 shadow-sm">
                <div class="card-body">
                  <h3 class="card-title text-base mb-2">{gettext("Invitation Link")}</h3>
                  <div class="flex flex-col sm:flex-row gap-2 items-stretch sm:items-center">
                    <.button phx-click={
                      JS.dispatch("phx:clipcopy", detail: %{id: url(~p"/testify/#{@token}")})
                      |> JS.push("copy_link")
                    }>
                      {gettext("Copy link")}
                    </.button>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <input
            :if={false}
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
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
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
