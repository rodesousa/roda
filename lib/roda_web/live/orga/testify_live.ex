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
    socket = Testify.pause_recording(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("resume_recording", _params, socket) do
    socket = Testify.resume_recording(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_recording", _params, socket) do
    socket = Testify.stop_recording(socket)
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
  def handle_event("recording_stopped", _params, socket) do
    socket = Testify.recording_stopped(socket)
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
  def render(assigns) do
    ~H"""
    <RodaWeb.Layouts.page
      flash={@flash}
      current="testify"
      scope={@current_scope}
    >
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Testify")} />
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
              <.link patch={ "#{@url}?mode=vocal"}>
                <button
                  role="tab"
                  class={["tab", @mode == "vocal" && "tab-active"]}
                >
                  Vocal
                </button>
              </.link>
              <.link patch={ "#{@url}?mode=text"}>
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
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end

  defp text_form(assigns) do
    ~H"""
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
      <button class="btn btn-primary w-full mt-4">
        {gettext("Submit Testimony")}
      </button>
    </.form>
    """
  end
end
