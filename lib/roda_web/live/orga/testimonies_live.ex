defmodule RodaWeb.Orga.TestimoniesLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.{Conversations, Date}
  alias Roda.{Organizations, Questions}

  @impl true
  def mount(_p, _session, socket) do
    socket =
      socket
      |> assign_testimonies()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="testimonies"
      scope={@current_scope}
    >
      <.page_content>
        <div class="">
          <%= for c <- @conversations do %>
            <div class="border-b pt-4">
              <div class="flex justify-between items-center">
                <div class="flex gap-x-2">
                  <div class="font-light text-cohortes-gray-placeholder">
                    {c.date}
                  </div>
                </div>
              </div>
              <div class="whitespace-pre-line -translate-y-4">
                {c.text}
              </div>
            </div>
          <% end %>
        </div>
      </.page_content>
    </.page>
    """
  end

  defp assign_testimonies(socket) do
    %{current_scope: scope} = socket.assigns

    conversation =
      Conversations.list_conversations_by_project_id(scope.project.id)
      |> Enum.map(fn %{chunks: chunks, inserted_at: date} ->
        text =
          Enum.sort_by(chunks, & &1.position)
          |> Enum.reduce("", fn c, acc ->
            """
            #{acc}
            #{c.text}
            """
          end)

        %{text: text, date: Date.display_date(date, [:short])}
      end)

    assign(socket, conversations: conversation)
  end
end
