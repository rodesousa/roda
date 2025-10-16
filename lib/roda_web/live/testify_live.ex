defmodule RodaWeb.TestifyLive do
  @moduledoc """
  Provides an interface for users to share their testimony either vocally or through text.
  """
  use RodaWeb, :live_view

  alias Roda.Conversations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, init_assigns(socket)}
  end

  defp init_assigns(socket) do
    project =
      Roda.Organization.Project
      |> Roda.Repo.all()
      |> hd()

    socket
    |> assign(
      recording_state: :idle,
      organization_id: project.organization_id,
      project_id: project.id,
      text_content: "",
      chunks: [],
      conversation_id: nil
    )
  end

  @impl true
  def handle_params(params, _, socket) do
    mode =
      case Map.get(params, "mode") do
        mode when mode in ["vocal", "text"] -> mode
        _ -> "vocal"
      end

    socket =
      socket
      |> assign(
        mode: mode,
        text_form: to_form(%{"text" => ""})
      )

    {:noreply, socket}
  end

  # Vocal mode events (from test_live.ex)
  @impl true
  def handle_event("start_recording", _params, socket) do
    ass = socket.assigns
    conversation = Conversations.add_conversation!(%{project_id: ass.project_id})

    {:noreply,
     socket
     |> assign(
       recording_state: :recording,
       conversation_id: conversation.id
     )
     |> push_event(
       "start_recording",
       %{id: conversation.id}
     )}
  end

  @impl true
  def handle_event("pause_recording", _params, socket) do
    {:noreply,
     socket
     |> assign(:recording_state, :paused)
     |> push_event("pause_recording", %{})}
  end

  @impl true
  def handle_event("resume_recording", _params, socket) do
    ass = socket.assigns

    {:noreply,
     socket
     |> assign(:recording_state, :recording)
     |> push_event("resume_recording", %{id: ass.conversation_id})}
  end

  @impl true
  def handle_event("stop_recording", _params, socket) do
    ass = socket.assigns

    {:noreply,
     socket
     |> assign(:recording_state, :idle)
     |> push_event("stop_recording", %{id: ass.conversation_id})}
  end

  @impl true
  def handle_event("recording_started", %{"mimeType" => _mime}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("recording_paused", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("recording_resumed", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("recording_stopped", _params, socket) do
    ass = socket.assigns

    %{conversation_id: ass.conversation_id}
    |> Roda.Workers.TranscribeWorker.new()
    |> Oban.insert()

    {:noreply,
     socket
     |> put_flash(:info, "Recording saved successfully! Processing your testimony...")
     |> assign(conversation_id: nil, chunks: [])}
  end

  @impl true
  def handle_event("chunk_uploaded", %{"path" => path}, socket) do
    {:noreply, socket |> update(:chunks, fn chunks -> [path | chunks] end)}
  end

  @impl true
  def handle_event("chunk_upload_error", %{"error" => error}, socket) do
    {:noreply, socket |> put_flash(:error, "Upload error: #{error}")}
  end

  @impl true
  def handle_event("recording_error", %{"error" => error}, socket) do
    {:noreply, socket |> put_flash(:error, "Recording error: #{error}")}
  end

  # Text mode events
  @impl true
  def handle_event("update_text", %{"text" => text}, socket) do
    {:noreply, assign(socket, :text_content, text)}
  end

  @impl true
  def handle_event("submit_text", %{"text" => text}, socket) do
    ass = socket.assigns

    case String.trim(text) do
      "" ->
        {:noreply, put_flash(socket, :error, "Please enter your testimony before submitting")}

      text ->
        conversation =
          Conversations.add_conversation!(%{project_id: ass.project_id, fully_transcribed: true})

        Conversations.add_chunk!(%{
          position: 0,
          conversation_id: conversation.id,
          path: nil,
          text: text
        })

        %{
          organization_id: ass.organization_id,
          conversation_id: conversation.id
        }
        |> Roda.Workers.EmbeddingWorker.new()
        |> Oban.insert!()

        %{
          organization_id: ass.organization_id,
          conversation_id: conversation.id
        }
        |> Roda.Workers.EntityExtractionWorker.new()
        |> Oban.insert!()

        {:noreply,
         socket
         |> put_flash(:info, "Testimony submitted successfully! Processing your content...")
         |> assign(text_content: "")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 flex items-center justify-center p-4">
      <div class="card w-full max-w-2xl bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="card-title text-3xl font-bold text-center justify-center mb-2">
            Share Your Testimony
          </h1>
          <p class="text-center text-base-content/70 mb-6">
            Choose how you'd like to share your experience
          </p>
          
    <!-- Tabs -->
          <div role="tablist" class="tabs tabs-boxed mb-6">
            <.link navigate={~p"/testify?mode=vocal"}>
              <button
                role="tab"
                class={["tab", @mode == "vocal" && "tab-active"]}
              >
                Vocal
              </button>
            </.link>

            <.link navigate={~p"/testify?mode=text"}>
              <button
                role="tab"
                class={["tab", @mode == :text && "tab-active"]}
              >
                Text
              </button>
            </.link>
          </div>
          
    <!-- Vocal Mode -->
          <%= if @mode == "vocal" do %>
            <div phx-hook="Recorder" id="audio-recorder" class="flex flex-col items-center py-8">
              <%= if @recording_state == :idle do %>
                <button
                  phx-click="start_recording"
                  class="btn btn-circle btn-primary w-32 h-32 mb-6"
                  aria-label="Start recording"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-16 w-16"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                    />
                  </svg>
                </button>
                <p class="text-center text-base-content/70">
                  Tap the microphone to start recording your testimony
                </p>
              <% end %>

              <%= if @recording_state == :recording do %>
                <div class="mb-6">
                  <div class="animate-pulse">
                    <div class="btn btn-circle btn-error w-32 h-32 flex items-center justify-center">
                      <div class="w-8 h-8 bg-white rounded-full"></div>
                    </div>
                  </div>
                </div>
                <div class="flex gap-4">
                  <button phx-click="pause_recording" class="btn btn-warning">
                    Pause
                  </button>
                  <button phx-click="stop_recording" class="btn btn-neutral">
                    Save
                  </button>
                </div>
                <p class="text-center text-base-content/70 mt-4">Recording in progress...</p>
              <% end %>

              <%= if @recording_state == :paused do %>
                <div class="mb-6">
                  <div class="btn btn-circle btn-warning w-32 h-32 flex items-center justify-center">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-16 w-16"
                      fill="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
                    </svg>
                  </div>
                </div>
                <div class="flex gap-4">
                  <button phx-click="resume_recording" class="btn btn-success">
                    Resume
                  </button>
                  <button phx-click="stop_recording" class="btn btn-neutral">
                    Save
                  </button>
                </div>
                <p class="text-center text-base-content/70 mt-4">Recording paused</p>
              <% end %>

              <%= if length(@chunks) > 0 do %>
                <div class="text-sm text-base-content/50 mt-4">
                  Chunks uploaded: {length(@chunks)}
                </div>
              <% end %>
            </div>
          <% end %>
          
    <!-- Text Mode -->
          <%= if @mode == "text" do %>
            <div class="py-4">
              <.text_form text_form={@text_form} />
            </div>
          <% end %>
          
    <!-- Footer -->
          <div class="divider"></div>
          <p class="text-center text-sm text-base-content/60">
            All testimonies are confidential and handled with care
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp text_form(assigns) do
    ~H"""
    <.form
      :let={f}
      id="text_form"
      for={@text_form}
      phx-submit="submit_text"
    >
      <.input
        type="textarea"
        field={f[:text]}
        placeholder={gettext("Share your testimony here...")}
      />
      <button class="btn btn-primary w-full mt-4">
        {gettext("Submit Testimony")}
      </button>
    </.form>
    """
  end
end
