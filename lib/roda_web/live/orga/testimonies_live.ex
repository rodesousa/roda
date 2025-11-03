defmodule RodaWeb.Orga.TestimoniesLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.{Conversations, Date}

  @params_to_store ["page"]

  @impl true
  def mount(_p, _session, socket) do
    socket =
      socket
      |> assign_testimonies()

    {:ok, socket}
  end

  @impl true
  def handle_event("conversation:delete:set", %{"id" => id}, socket) do
    socket = assign(socket, conversation_id_to_delete: id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", _, socket) do
    %{current_scope: scope} = ass = socket.assigns
    last = List.last(ass.conversations)
    new_conversations = list_conversation(scope, last_id: last.id)

    socket =
      assign(socket, conversations: ass.conversations ++ new_conversations)

    {:noreply, socket}
  end

  @impl true
  def handle_event("conversation:delete", _, socket) do
    %{current_scope: scope} = ass = socket.assigns

    socket =
      with true <-
             Conversations.can_delete_conversation?(
               scope,
               ass.conversation_id_to_delete
             ) do
        Conversations.delete_conversation(ass.conversation_id_to_delete)

        socket
        |> assign_testimonies()
        |> push_event("close:modal", %{id: "delete-conversation"})
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.modal id="delete-conversation">
      {gettext("DELETE?!")}
      <.button phx-click="conversation:delete">
        OUI
      </.button>
    </.modal>
    <.page
      current="testimonies"
      scope={@current_scope}
    >
      <.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Testimonies")} />
        <%= for c <- @conversations do %>
          <div class="border-b pt-4">
            <div class="flex justify-between items-center">
              <div class="flex gap-x-2">
                <div class="font-light text-cohortes-gray-placeholder">
                  {c.date}
                </div>
                <.button
                  phx-click={JS.push("conversation:delete:set") |> show_modal("delete-conversation")}
                  phx-value-id={c.id}
                >
                  {gettext("Delete")}
                </.button>
              </div>
            </div>
            <div class="whitespace-pre-line -translate-y-4">
              {c.text}
            </div>
          </div>
        <% end %>
        <div class="justify-center flex mt-4">
          <.button phx-click="paginate">
            {gettext("See more")}
          </.button>
        </div>
      </.page_content>
    </.page>
    """
  end

  defp assign_testimonies(socket) do
    %{current_scope: scope} = socket.assigns
    conversations = list_conversation(scope)
    assign(socket, conversations: conversations)
  end

  defp list_conversation(scope, params \\ []) do
    params
    |> IO.inspect(label: "1")

    Conversations.list_conversations_paginate(scope, params)
    |> Enum.map(fn %{chunks: chunks, inserted_at: date, id: id} ->
      text =
        Enum.sort_by(chunks, & &1.position)
        |> Enum.reduce("", fn c, acc ->
          """
          #{acc}
          #{c.text}
          """
        end)

      %{text: text, date: Date.display_date(date, [:short]), id: id}
    end)
  end
end
