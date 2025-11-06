defmodule RodaWeb.Orga.Prompt.PromptsLive do
  use RodaWeb, :live_view

  alias Roda.Prompts

  @impl true
  def mount(_params, _session, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      socket
      |> assign(:prompts, Prompts.list_conversations(scope))

    {:ok, socket}
  end

  @impl true
  def handle_event("new_conversation", _params, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      with true <- scope.membership.role in ["admin", "manager"] do
        {:ok, conversation} =
          Prompts.create_conversation(scope, %{
            title: gettext("New conversation")
          })

        push_navigate(socket,
          to:
            ~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/prompts/#{conversation.id}"
        )
      else
        _ ->
          socket
          |> put_flash(:error, gettext("You are not authorized to create a conversation."))
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <RodaWeb.Layouts.page
      flash={@flash}
      current="ask"
      scope={@current_scope}
    >
      <:extends_sidebar>
        <div class="space-y-2">
          <%= for conv <- @prompts do %>
            <.link navigate={
              ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/prompts/#{conv.id}"
            }>
              <button
                phx-click="select_conversation"
                class="w-full text-left p-3 rounded-lg transition-colors break-words cursor-pointer hover:bg-base-300"
              >
                <div class="font-medium truncate">{conv.title}</div>
                <div class="text-xs opacity-70">
                  {Calendar.strftime(conv.updated_at, "%d/%m/%Y %H:%M")}
                </div>
              </button>
            </.link>
          <% end %>
        </div>
      </:extends_sidebar>
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Prompts")} />
        <div class="flex-1 flex items-center justify-center">
          <div class="text-center">
            <p class="text-lg mb-4">{gettext("Select a conversation or start a new")}</p>
            <button phx-click="new_conversation" class="btn btn-primary">
              {gettext("New conversation")}
            </button>
          </div>
        </div>
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end
end
