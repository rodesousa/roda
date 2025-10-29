defmodule RodaWeb.Testify do
  import Phoenix.Component, only: [assign: 2, to_form: 1]
  import Phoenix.LiveView, only: [push_event: 3, put_flash: 3]
  alias Roda.{Conversations}

  use Gettext, backend: RodaWeb.Gettext

  def init_assigns(socket) do
    socket
    |> assign(
      recording_state: :idle,
      text_content: "",
      chunks: [],
      conversation_id: nil
    )
  end

  def handle_table(params, socket) do
    mode =
      case Map.get(params, "mode") do
        mode when mode in ["vocal", "text"] -> mode
        _ -> "vocal"
      end

    socket
    |> assign(
      mode: mode,
      text_form: to_form(%{"text" => ""})
    )
  end

  def start_recording(socket) do
    %{current_scope: scope} = socket.assigns
    conversation = Conversations.add_conversation!(%{project_id: scope.project.id})

    socket
    |> assign(
      recording_state: :recording,
      conversation_id: conversation.id
    )
    |> push_event(
      "start_recording",
      %{id: conversation.id}
    )
  end

  def pause_recording(socket) do
    socket
    |> assign(recording_state: :paused)
    |> push_event("pause_recording", %{})
  end

  def resume_recording(socket) do
    ass = socket.assigns

    socket
    |> assign(recording_state: :recording)
    |> push_event("resume_recording", %{id: ass.conversation_id})
  end

  def stop_recording(socket) do
    ass = socket.assigns

    socket
    |> assign(recording_state: :idle)
    |> push_event("stop_recording", %{id: ass.conversation_id})
  end

  def recording_stopped(socket) do
    ass = socket.assigns

    %{conversation_id: ass.conversation_id}
    |> Roda.Workers.TranscribeWorker.new()
    |> Oban.insert()

    socket
    |> put_flash(:info, gettext("Recording saved successfully! Processing your testimony..."))
    |> assign(conversation_id: nil, chunks: [])
  end

  def chunk_uploaded(socket, %{"path" => path}) do
    assign(socket, chunks: [path | socket.assigns.chunks])
  end

  def chunk_upload_error(socket, %{"error" => error}) do
    put_flash(socket, :error, "Upload error: #{error}")
  end

  def recording_error(socket, %{"error" => error}) do
    put_flash(socket, :error, "Recording error: #{error}")
  end

  def update_text(socket, %{"text" => text}) do
    assign(socket, text_content: text)
  end

  def submit_text(socket, %{"text" => text}) do
    %{current_scope: scope} = socket.assigns

    case String.trim(text) do
      "" ->
        put_flash(socket, :error, gettext("Please enter your testimony before submitting"))

      text ->
        conversation =
          Conversations.add_conversation!(%{
            project_id: scope.project.id,
            fully_transcribed: true
          })

        Conversations.add_chunk!(%{
          position: 0,
          conversation_id: conversation.id,
          path: nil,
          text: text
        })

        # %{
        #   organization_id: ass.organization_id,
        #   conversation_id: conversation.id
        # }
        # |> Roda.Workers.EmbeddingWorker.new()
        # |> Oban.insert!()

        # %{
        #   organization_id: ass.organization_id,
        #   conversation_id: conversation.id
        # }
        # |> Roda.Workers.EntityExtractionWorker.new()
        # |> Oban.insert!()

        socket
        |> put_flash(:info, "Testimony submitted successfully! Processing your content...")
        |> assign(text_content: "")
        |> push_event("reset-form", %{})
    end
  end
end
