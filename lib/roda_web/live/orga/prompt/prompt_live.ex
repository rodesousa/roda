defmodule RodaWeb.Orga.Prompt.PromptLive do
  @moduledoc """
  Technical debt:
  - If a prompt doesnt work, user cannot resend the same prompt and the prompt are saved

  Error:
  - For the first time, the textarea are in the top of the page
  """
  use RodaWeb, :live_view

  alias Roda.{Prompts, LLM, Conversations, Organizations}

  @impl true
  def mount(%{"prompt_id" => prompt_id}, _session, socket) do
    socket =
      socket
      |> assign_init()
      |> assign_prompt(prompt_id)

    {:ok, socket}
  end

  defp assign_init(socket) do
    %{current_scope: scope} = socket.assigns

    socket
    |> assign(
      conversations: [],
      is_streaming: false,
      current_conversation_form: nil,
      prompts: Prompts.list_conversations(scope),
      period: %{begin_at: nil, end_at: nil},
      input_value: nil
    )
  end

  defp assign_prompt(socket, id) do
    %{current_scope: scope} = socket.assigns

    case Prompts.get_conversation(scope, id) do
      {:ok, conversation} ->
        prompt_message = Prompts.get_prompt_conversation(scope, id)

        changeset =
          Roda.Prompts.PromptConversation.update_title_changeset(prompt_message, %{
            title: prompt_message.title
          })

        socket
        |> assign(
          current_conversation: conversation,
          messages: conversation.messages,
          streaming_content: "",
          current_conversation_form: to_form(changeset)
        )

      {:error, _} ->
        push_navigate(socket,
          to: ~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/prompts"
        )
    end
  end

  @impl true
  def handle_event("delete", _p, socket) do
    %{current_scope: scope} = ass = socket.assigns

    socket =
      with true <- scope.membership.role == "admin" do
        Prompts.delete_conversation(scope, ass.current_conversation.id)

        socket
        |> assign_init()
        |> push_navigate(
          to: ~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/prompts"
        )
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message_text}, socket) do
    ass = socket.assigns

    if String.trim(message_text) == "" or (ass.conversations == [] and ass.messages == []) do
      socket =
        socket
        |> put_flash(
          :error,
          gettext("Please enter a message and select a date range in the calendar.")
        )

      {:noreply, socket}
    else
      %{current_conversation: conversation, messages: messages, current_scope: scope} =
        socket.assigns

      provider =
        get_provider(scope)

      prompt =
        if ass.messages == [] do
          build_prompt(socket, message_text)
        else
          message_text
        end

      # Save user message
      {:ok, user_message} = Prompts.add_message(conversation.id, "user", prompt)

      # Update messages
      updated_messages = messages ++ [user_message]

      # Prepare messages for API
      api_messages =
        updated_messages
        |> Enum.map(fn msg -> %{role: msg.role, content: msg.content} end)

      # Start streaming in a separate process
      pid = self()

      Task.start(fn ->
        LLM.chat_completion_stream(provider, api_messages)
        |> Enum.each(fn
          {:chunk, text} ->
            send(pid, {:append_chunk, text})

          {:done} ->
            send(pid, :stream_complete)

          {:error, reason} ->
            send(pid, {:stream_error, reason})
        end)
      end)

      socket =
        socket
        |> assign(:messages, updated_messages)
        |> assign(:streaming_content, "")
        |> assign(:is_streaming, true)

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("date_range_selected", %{"begin_at" => begin_at, "end_at" => end_at}, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      with {:ok, begin_at} <- NaiveDateTime.from_iso8601(begin_at),
           {:ok, end_at} <- NaiveDateTime.from_iso8601(end_at) do
        conversations =
          Conversations.list_conversations_by_range(scope, begin_at, end_at)

        socket
        |> assign(conversations: conversations)
        |> assign(period: %{begin_at: begin_at, end_at: end_at})
      else
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("rename", %{"prompt_conversation" => args}, socket) do
    %{current_scope: scope} = ass = socket.assigns

    prompt_conversation =
      Prompts.get_prompt_conversation(scope, ass.current_conversation.id)

    socket =
      case Prompts.update_conversation_title(prompt_conversation, args) do
        {:ok, conversation} ->
          socket
          |> assign(
            current_conversation: conversation,
            prompts: Prompts.list_conversations(scope),
            current_conversation_form:
              to_form(
                Roda.Prompts.PromptConversation.update_title_changeset(conversation, %{
                  title: conversation.title
                })
              )
          )
          |> push_event("close:modal", %{id: "rename"})

        {:error, changeset} ->
          socket
          |> assign(current_conversation_form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:append_chunk, text}, socket) do
    updated_content = socket.assigns.streaming_content <> text
    {:noreply, assign(socket, :streaming_content, updated_content)}
  end

  @impl true
  def handle_info(:stream_complete, socket) do
    %{
      current_conversation: conversation,
      streaming_content: content,
      messages: messages,
      period: period
    } =
      socket.assigns

    if content != "" do
      socket =
        case messages do
          [_one] ->
            {:ok, conversation} =
              Prompts.update_conversation_period(conversation, period)

            assign(socket, current_conversation: conversation)

          _ ->
            socket
        end

      # Save assistant message
      {:ok, assistant_message} = Prompts.add_message(conversation.id, "assistant", content)

      socket =
        socket
        |> assign(:messages, messages ++ [assistant_message])
        |> assign(:streaming_content, "")
        |> assign(:is_streaming, false)

      {:noreply, socket}
    else
      {:noreply, assign(socket, :is_streaming, false)}
    end
  end

  @impl true
  def handle_info({:stream_error, reason}, socket) do
    error_message =
      case reason do
        :rate_limit_exceeded ->
          gettext("Too many requests. Please wait a few seconds and try again.")

        :bad_api_key ->
          gettext(
            "Authentication error with the AI provider. Please check your API configuration."
          )

        :server_error ->
          gettext("The AI service is temporarily unavailable. Please try again later.")

        {:http_error, status} ->
          gettext("HTTP error %{status}: Unable to connect to the AI service.", %{status: status})

        _ ->
          gettext("An error occurred: %{reason}", %{reason: inspect(reason)})
      end

    socket =
      socket
      |> assign(:is_streaming, false)
      |> assign(:streaming_content, "")
      |> put_flash(:error, error_message)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.modal id="delete">
      <div class="space-y-4">
        <h2 class="text-xl font-bold">
          {gettext("Delete Prompt")}
        </h2>

        <p class="text-sm text-base-content/70">
          {gettext("Are you sure you want to remove this prompt? This action cannot be undone.")}
        </p>

        <div class="flex justify-end gap-2 pt-4">
          <.button phx-click={hide_modal("delete")} class="btn btn-ghost">
            {gettext("Cancel")}
          </.button>
          <.button phx-click="delete" class="btn btn-error">
            {gettext("Delete")}
          </.button>
        </div>
      </div>
    </.modal>

    <.modal id="rename">
      <div class="space-y-4">
        <h2 class="text-xl font-bold">
          {gettext("Rename Prompt")}
        </h2>
        <.form :let={f} for={@current_conversation_form} phx-submit="rename">
          <div class="flex-col space-y-4 py-4">
            <.input field={f[:title]} label={gettext("Title")} />
          </div>
          <div class="flex justify-end gap-2 pt-4">
            <.button phx-click={hide_modal("rename")} type="button" class="btn btn-ghost">
              {gettext("Cancel")}
            </.button>

            <.button type="submit">
              {gettext("Rename")}
            </.button>
          </div>
        </.form>
      </div>
    </.modal>

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
              <button class={[
                "w-full text-left p-3 rounded-lg transition-colors break-words cursor-pointer",
                if(@current_conversation && @current_conversation.id == conv.id,
                  do: "bg-primary text-primary-content",
                  else: "hover:bg-base-300"
                )
              ]}>
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
        
    <!-- Header with date and actions -->
        <div class="flex space-x-2 items-center mb-4">
          <div>
            <%= if @current_conversation.begin_at do %>
              {"#{Calendar.strftime(@current_conversation.begin_at, "%d/%m/%Y")} to #{Calendar.strftime(@current_conversation.end_at, "%d/%m/%Y")}"}
            <% else %>
              <input
                id="flatpickr"
                phx-hook="Flatpickr"
                type="text"
                class="input input-bordered w-full max-w-xs"
                placeholder={gettext("Select date range...")}
                readonly
              />
            <% end %>
          </div>

          <.button class="btn btn-primary btn-outline btn-sm" phx-click={show_modal("rename")}>
            {gettext("Rename")}
          </.button>
          <.button class="btn btn-error btn-outline btn-sm" phx-click={show_modal("delete")}>
            {gettext("Delete")}
          </.button>
        </div>
        
    <!-- Scrollable messages area -->
        <div class="overflow-y-auto space-y-4" id="messages-container">
          <%= for message <- @messages do %>
            <div class={[
              "chat",
              if(message.role == "user", do: "chat-end", else: "chat-start")
            ]}>
              <% {content, testimonies} = format_message_with_collapsible(message.content) %>
              <div
                id={"message-#{message.id}"}
                class="chat-bubble prose prose-sm max-w-none"
                phx-hook="MarkdownCitations"
                data-content={content}
                data-citation-map="{}"
                data-modals-html=""
              >
              </div>
              <details
                :if={testimonies not in ["", nil]}
                class="collapse collapse-arrow bg-base-200 my-2 cursor-pointer"
              >
                <div class="collapse-content">
                  <pre class="text-xs opacity-70">{testimonies}</pre>
                </div>
              </details>
            </div>
          <% end %>
          
    <!-- Streaming Message -->
          <%= if @is_streaming && @streaming_content != "" do %>
            <div class="chat chat-start">
              <div
                id="ia-streaming-content"
                class="chat-bubble prose prose-sm max-w-none"
                phx-hook="MarkdownCitations"
                data-content={@streaming_content}
                data-citation-map="{}"
                data-modals-html=""
                phx-update="ignore"
              >
                <span class="loading loading-dots loading-xs"></span>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Always visible input -->
        <form phx-submit="send_message" class="flex space-x-2 items-center mt-4 mb-4">
          <div class="flex gap-2 flex-1">
            <.input
              type="textarea"
              name="message"
              value={@input_value}
              placeholder={gettext("Type your message...")}
              disabled={@is_streaming}
              class="bg-base-200 w-full textarea rounded-xl"
              cols="10"
            />
          </div>
          <.button
            class="btn btn-primary"
            disabled={@is_streaming}
          >
            <%= if @is_streaming do %>
              <span class="loading loading-spinner"></span>
            <% else %>
              {gettext("Send")}
            <% end %>
          </.button>
        </form>
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end

  defp format_message_with_collapsible(content) do
    case Regex.run(~r/<testimonies>(.*)<\/testimonies>/s, content) do
      [_, testimonies_content] ->
        question_part = String.replace(content, ~r/<testimonies>.*<\/testimonies>/s, "")
        {question_part, testimonies_content}

      nil ->
        {content, nil}
    end
  end

  defp build_prompt(socket, question_prompt) do
    ass = socket.assigns

    ts =
      Enum.reduce(ass.conversations, "", fn %{chunks: chunks}, acc ->
        temp =
          chunks
          |> Enum.sort_by(& &1.position)
          |> Enum.reduce("", fn %{text: text, id: _id}, acc2 ->
            """
            #{acc2}

            #{text}
            """
          end)

        """
        #{acc}

        Témoignage:
        #{temp}
        ---
        """
      end)

    """
    <question>
    #{question_prompt}
    </question>

    <testimonies>
    #{ts}
    </testimonies>
    """
  end

  defp get_provider(%Roda.Accounts.Scope{} = s) do
    Organizations.get_provider_by_organization(s)
  end
end
