defmodule RodaWeb.Orga.TestifyLive do
  @moduledoc """
  """
  use RodaWeb, :live_view

  alias RodaWeb.Testify

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      socket
      |> Testify.init_assigns()
      |> assign(url: url(~p"/testify/#{token}"))

    {:ok, socket}
  end

  @impl true
  def mount(_, _session, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      socket
      |> Testify.init_assigns()
      |> assign(
        url: url(~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/testify")
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    socket = Testify.handle_table(params, socket)

    {:noreply, socket}
  end

  @impl true
  def handle_event("start_recording", _params, socket) do
    socket = Testify.start_recording(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("pause_recording", _params, socket) do
    socket =
      socket
      |> assign(recording_state: :paused)
      |> push_event("pause_recording", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("resume_recording", _params, socket) do
    socket = Testify.resume_recording(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_recording", _params, socket) do
    ass = socket.assigns

    socket =
      socket
      |> assign(recording_state: :idle)
      |> push_event("stop_recording", %{id: ass.conversation_id})

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_recording", _p, socket) do
    ass = socket.assigns

    %{
      conversation_id: ass.conversation_id,
      action: "delete"
    }
    |> Roda.Workers.TranscribeWorker.new()
    |> Oban.insert()

    socket =
      socket
      |> put_flash(:info, gettext("Recording saved successfully! Processing your testimony..."))
      |> assign(conversation_id: nil, recording_state: :idle)

    {:noreply, socket}
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
  def handle_event("recording_stopped", %{"total_chunks" => total_chunks}, socket) do
    ass = socket.assigns

    %{
      conversation_id: ass.conversation_id,
      total_chunks: total_chunks
    }
    |> Roda.Workers.TranscribeWorker.new()
    |> Oban.insert()

    socket =
      socket
      |> put_flash(:info, gettext("Recording saved successfully! Processing your testimony..."))
      |> assign(conversation_id: nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("chunk_uploaded", %{"path" => _} = params, socket) do
    socket = Testify.chunk_uploaded(socket, params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("chunk_upload_error", %{"error" => _} = params, socket) do
    socket = Testify.chunk_upload_error(socket, params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("recording_error", %{"error" => _} = params, socket) do
    socket = Testify.recording_error(socket, params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_text", %{"text" => _} = params, socket) do
    socket = Testify.update_text(socket, params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_text", %{"text" => _text} = params, socket) do
    socket = Testify.submit_text(socket, params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("test_mic", _params, socket) do
    socket = Testify.start_mic_test(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_mic_test", _params, socket) do
    socket = Testify.stop_mic_test(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("mic_test_started", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("mic_test_stopped", _params, socket) do
    socket = Testify.stop_mic_test(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("mic_test_error", %{"error" => _error} = params, socket) do
    socket = Testify.mic_test_error(socket, params)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <RodaWeb.Layouts.page
      flash={@flash}
      current="testify"
      scope={@current_scope}
    >
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Testify")} />
        <div class="card-body">
          <h1 class="card-title text-3xl font-bold text-center justify-center mb-2">
            {gettext("Share Your Testimony")}
          </h1>
          <div class="flex flex-col items-center">
            <p class="text-center text-base-content/70 mb-6">
              {gettext("Choose how you'd like to share your experience")}
            </p>

            <div role="tablist" class="tabs tabs-boxed mb-6 p-1 bg-base-200">
              <.link patch={"#{@url}?mode=vocal"} class="flex-1">
                <button
                  role="tab"
                  class={[
                    "p-4 space-x-2 flex font-semibold transition-all cursor-pointer",
                    @mode == "vocal" && "tab-active bg-primary text-primary-content"
                  ]}
                >
                  <.icon name="hero-microphone" class="w-6 h-6" />
                  <div>{gettext("Vocal")}</div>
                </button>
              </.link>
              <.link patch={"#{@url}?mode=text"} class="flex-1">
                <button
                  role="tab"
                  class={[
                    "p-4 space-x-2 flex font-semibold transition-all  cursor-pointer",
                    @mode == "text" && "tab-active bg-primary text-primary-content"
                  ]}
                >
                  <.icon name="hero-pencil-square" class="w-6 h-6" />
                  <div>{gettext("Text")}</div>
                </button>
              </.link>
            </div>
          </div>

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
                <p class="text-center text-base-content/70 mb-4">
                  {gettext("Tap the microphone to start recording your testimony")}
                </p>

                <div class="divider">{gettext("OR")}</div>

                <button
                  phx-click="test_mic"
                  class="btn btn-secondary gap-2"
                >
                  <.icon name="hero-microphone" class="w-5 h-5" />
                  {gettext("Test Microphone")}
                </button>
              <% end %>

              <%= if @recording_state == :testing_mic do %>
                <div class="card bg-base-200 shadow-xl w-full max-w-md">
                  <div class="card-body items-center text-center">
                    <h3 class="card-title text-xl mb-4">
                      <.icon name="hero-microphone" class="w-6 h-6 text-secondary" />
                      {gettext("Testing Microphone")}
                    </h3>

                    <p class="text-sm text-base-content/70 mb-4">
                      {gettext(
                        "Speak into your microphone. The bar below will show your audio level."
                      )}
                    </p>

                    <div class="w-full mb-4">
                      <div class="flex items-center gap-2 mb-2">
                        <span class="text-sm">{gettext("Level")}:</span>
                        <span class="font-bold" id="mic-test-level-text">0%</span>
                        <span id="mic-test-success-badge" class="badge badge-success gap-1 hidden">
                          <.icon name="hero-check" class="w-4 h-4" />
                          {gettext("Voice detected!")}
                        </span>
                      </div>
                      <progress
                        id="mic-test-progress"
                        class="progress progress-warning w-full h-4"
                        value="0"
                        max="100"
                      >
                      </progress>
                    </div>

                    <button
                      phx-click="stop_mic_test"
                      class="btn btn-neutral btn-wide"
                    >
                      {gettext("Stop Test")}
                    </button>
                  </div>
                </div>
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
                </div>
                <p class="text-center text-base-content/70 mt-4">
                  {gettext("Recording in progress...")}
                </p>
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
                  <button phx-click="delete_recording" class="btn btn-error">
                    {gettext("Delete")}
                  </button>
                  <button phx-click="resume_recording" class="btn btn-success">
                    {gettext("Resume")}
                  </button>
                  <button phx-click="stop_recording" class="btn btn-neutral">
                    {gettext("Save")}
                  </button>
                </div>
                <p class="text-center text-base-content/70 mt-4">{gettext("Recording paused")}</p>
              <% end %>
            </div>
          <% end %>

          <%= if @mode == "text" do %>
            <div class="py-4">
              <.form
                :let={f}
                id="text_form"
                for={@text_form}
                phx-submit="submit_text"
                phx-hook="ResetForm"
              >
                <.input
                  type="textarea"
                  field={f[:text]}
                  placeholder={gettext("Share your testimony here...")}
                />
                <div class="text-right">
                  <.button>
                    {gettext("Submit your testimony")}
                  </.button>
                </div>
              </.form>
            </div>
          <% end %>

          <div class="divider"></div>
          <p class="text-center text-sm text-base-content/60">
            {gettext("All testimonies are confidential.")}
          </p>
        </div>
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end
end
