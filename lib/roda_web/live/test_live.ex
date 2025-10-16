defmodule RodaWeb.TestLive do
  use RodaWeb, :live_view

  alias Roda.Conversations
  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> init_assign()}
  end

  defp init_assign(socket) do
    project = 
Roda.Organization.Project
    |> Roda.Repo.all()
    |> hd()
    socket
    |> assign(
      recording_state: :idle,
      organization_id: project.organization_id,
      project_id: project.id,
      chunks: []
    )
  end

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

    {:noreply, socket}
  end

  @impl true
  def handle_event("test", data, socket) do
    data
    |> IO.inspect(label: "DATA")

    {:noreply, socket}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8" phx-hook="Recorder" id="audio-recorder">
      <h1 class="text-2xl font-bold mb-4">Audio Recorder</h1>

      <div class="space-x-2 mb-4">
        <%= if @recording_state == :idle do %>
          <button
            phx-click="start_recording"
            class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
          >
            Record
          </button>
        <% end %>

        <%= if @recording_state == :recording do %>
          <button
            phx-click="pause_recording"
            class="px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600"
          >
            Pause
          </button>
          <button
            phx-click="stop_recording"
            class="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
          >
            Save
          </button>
        <% end %>

        <%= if @recording_state == :paused do %>
          <button
            phx-click="resume_recording"
            class="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
          >
            Resume
          </button>
          <button
            phx-click="stop_recording"
            class="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
          >
            Save
          </button>
        <% end %>
      </div>

      <div class="mt-4">
        <p class="font-semibold">Status: {@recording_state}</p>
        <p class="text-sm text-gray-600">Chunks uploaded: {length(@chunks)}</p>
      </div>

      <%= if length(@chunks) > 0 do %>
        <div class="mt-4">
          <h2 class="font-semibold mb-2">Uploaded Chunks:</h2>
          <ul class="list-disc pl-5 text-sm">
            <%= for chunk <- Enum.reverse(@chunks) do %>
              <li>{chunk}</li>
            <% end %>
          </ul>
        </div>
      <% end %>
    </div>
    """
  end
end
