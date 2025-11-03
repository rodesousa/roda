defmodule RodaWeb.Orga.PromptLive do
  use RodaWeb, :live_view

  alias Roda.{Prompts, LLM, Conversations, Organizations}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_init()

    {:ok, socket}
  end

  def assign_init(socket) do
    %{current_scope: scope} = socket.assigns

    socket
    |> assign(:conversations, [])
    |> assign(current_conversation_form: nil)
    |> assign(:prompts, Prompts.list_conversations(scope))
    |> assign(:current_conversation, nil)
    |> assign(:messages, [])
    |> assign(:streaming_content, "")
    |> assign(:is_streaming, false)
    |> assign(:input_value, "")
    |> assign(period: %{begin_at: nil, end_at: nil})
  end

  @impl true
  def handle_event("delete", p, socket) do
    %{current_scope: scope} = ass = socket.assigns

    Prompts.delete_conversation(scope, ass.current_conversation.id)

    socket =
      socket
      |> assign_init()
      |> push_event("close:modal", %{id: "delete"})

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
  def handle_event("date_range_selected", %{"begin_at" => begin_at, "end_at" => end_at}, socket) do
    %{current_scope: scope} = ass = socket.assigns

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
  def handle_event("new_conversation", _params, socket) do
    %{current_scope: scope} = socket.assigns

    {:ok, conversation} =
      Prompts.create_conversation(scope, %{
        title: gettext("New conversation")
      })

    prompts = Prompts.list_conversations(scope)

    changeset =
      Roda.Prompts.PromptConversation.update_title_changeset(conversation, %{
        title: conversation.title
      })

    socket =
      socket
      |> assign(:prompts, prompts)
      |> assign(:current_conversation, conversation)
      |> assign(:messages, [])
      |> assign(:streaming_content, "")
      |> assign(:current_conversation_form, to_form(changeset))

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_conversation", %{"id" => id}, socket) do
    %{current_scope: scope} = socket.assigns

    case Prompts.get_conversation(scope, id) do
      {:ok, conversation} ->
        prompt_message = Prompts.get_prompt_conversation(scope, id)

        changeset =
          Roda.Prompts.PromptConversation.update_title_changeset(prompt_message, %{
            title: prompt_message.title
          })

        socket =
          socket
          |> assign(:current_conversation, conversation)
          |> assign(:messages, conversation.messages)
          |> assign(:streaming_content, "")
          |> assign(:current_conversation_form, to_form(changeset))

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Conversation not found"))}
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => message_text}, socket) do
    ass = socket.assigns

    if String.trim(message_text) == "" or (ass.conversations == [] and ass.messages == []) do
      socket =
        socket
        |> put_flash(:error, gettext("prompt empty and/or testimonies not selected"))

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
        |> assign(:input_value, "")

      {:noreply, socket}
    end
  end

  defp build_prompt(socket, question_prompt) do
    ass = socket.assigns

    ts =
      Enum.reduce(ass.conversations, "", fn %{chunks: chunks}, acc ->
        temp =
          chunks
          |> Enum.sort_by(& &1.position)
          |> Enum.reduce("", fn %{text: text, id: id}, acc2 ->
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

    socket =
      case messages do
        [_one] ->
          conversation
          |> IO.inspect(label: " IMPO")

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
  end

  @impl true
  def handle_info({:stream_error, reason}, socket) do
    socket =
      socket
      |> assign(:is_streaming, false)
      |> put_flash(:error, "Stream error: #{reason}")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.modal id="delete">
      {gettext("Are you sur to delete ?")}
      <.button phx-click="delete">
        OUI
      </.button>
    </.modal>

    <.modal id="rename">
      <.form :let={f} for={@current_conversation_form} phx-submit="rename">
        <div class="flex-col space-y-4 py-4">
          <.input field={f[:title]} label={gettext("Title")} />
        </div>
        <div class="modal-action">
          <.button type="submit">
            {gettext("Rename")}
          </.button>
        </div>
      </.form>
    </.modal>

    <.page
      current="orgas"
      scope={@current_scope}
    >
      <:extends_sidebar>
        <div class="w-64 bg-base-200 p-4 overflow-y-auto">
          <div class="space-y-2">
            <%= for conv <- @prompts do %>
              <button
                phx-click="select_conversation"
                phx-value-id={conv.id}
                class={[
                  "w-full text-left p-3 rounded-lg transition-colors",
                  if(@current_conversation && @current_conversation.id == conv.id,
                    do: "bg-primary text-primary-content",
                    else: "hover:bg-base-300"
                  )
                ]}
              >
                <div class="font-medium truncate">{conv.title}</div>
                <div class="text-xs opacity-70">
                  {Calendar.strftime(conv.updated_at, "%d/%m/%Y %H:%M")}
                </div>
              </button>
            <% end %>
          </div>
        </div>
      </:extends_sidebar>
      <!-- Conversation Area -->
      <div class="flex-1 flex flex-col  h-full">
        <%= if @current_conversation do %>
          <!-- Messages -->
          <div class="flex-1 overflow-y-auto p-4 space-y-4">
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
            <div :if={@conversations != []}>
              {gettext("%{s} conversations", %{s: length(@conversations)})}
            </div>

            <.button phx-click={show_modal("rename")}>{gettext("Rename")}</.button>
            <.button phx-click={show_modal("delete")}>{gettext("Delete")}</.button>

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
                  class="collapse collapse-arrow bg-base-200 my-2"
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
          
    <!-- Input -->
          <form phx-submit="send_message" class="bg-base-200 mx-4 mb-6 rounded-xl flex gap-2">
            <input
              type="textarea"
              name="message"
              value={@input_value}
              placeholder={gettext("Type your message...")}
              class="w-full m-4"
              disabled={@is_streaming}
              cols="10"
              cols="10"
            />
            <button
              type="submit"
              class="btn btn-primary"
              disabled={@is_streaming}
            >
              <%= if @is_streaming do %>
                <span class="loading loading-spinner"></span>
              <% else %>
                {gettext("Send")}
              <% end %>
            </button>
          </form>
        <% else %>
          <!-- No conversation selected -->
          <div class="flex-1 flex items-center justify-center">
            <div class="text-center">
              <p class="text-lg mb-4">{gettext("Select a conversation or create a new one")}</p>
              <button phx-click="new_conversation" class="btn btn-primary">
                {gettext("New Conversation")}
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </.page>
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

  defp get_provider(%Roda.Accounts.Scope{} = s) do
    Organizations.get_provider_by_organization(s)
  end
end
