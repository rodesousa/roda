defmodule RodaWeb.Testify do
  @moduledoc """
  Technical debt:
  - useless, migrate to testify_live
  """
  import Phoenix.Component, only: [assign: 2, to_form: 1]
  import Phoenix.LiveView, only: [push_event: 3, put_flash: 3]
  alias Roda.{Conversations}

  use Gettext, backend: RodaWeb.Gettext

  def init_assigns(socket) do
    socket
    |> assign(
      recording_state: :idle,
      text_content: "",
      conversation_id: nil,
      audio_level: 0,
      mic_test_success: false
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
    conversation = Conversations.add_conversation!(%{project_id: scope.project.id, active: false})

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

  def resume_recording(socket) do
    ass = socket.assigns

    socket
    |> assign(recording_state: :recording)
    |> push_event("resume_recording", %{id: ass.conversation_id})
  end

  def chunk_uploaded(socket, %{"path" => _path}) do
    socket
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

  def start_mic_test(socket) do
    socket
    |> assign(recording_state: :testing_mic, audio_level: 0, mic_test_success: false)
    |> push_event("start_mic_test", %{})
  end

  def stop_mic_test(socket) do
    socket
    |> assign(recording_state: :idle, audio_level: 0)
  end

  def audio_level_update(socket, %{"level" => level}) do
    # Ensure level is an integer
    level = if is_integer(level), do: level, else: String.to_integer("#{level}")
    mic_test_success = socket.assigns.mic_test_success || level > 5

    IO.inspect(level, label: "Setting audio_level to")

    socket
    |> assign(audio_level: level, mic_test_success: mic_test_success)
  end

  def mic_test_error(socket, %{"error" => error}) do
    socket
    |> assign(recording_state: :idle)
    |> put_flash(:error, "Microphone test error: #{error}")
  end
end
