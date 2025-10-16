defmodule RodaWeb.TestifyLiveTest do
  use RodaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Roda.{Repo, Conversations}
  alias Roda.Conversations.{Chunk, Conversation}
  alias Roda.Organization.{Organization, Project}
  alias Roda.OrganizationFixtures

  setup do
    OrganizationFixtures.init_organization()
  end

  test "renders the page with vocal mode by default", %{conn: conn} do
    {:ok, _, html} = live(conn, ~p"/testify")
    assert html =~ "Tap the microphone to start recording your testimony"
  end

  test "switches mode test", %{conn: conn} do
    {:ok, _, html} = live(conn, ~p"/testify?mode=text")
    assert html =~ "Submit Testimony"
  end

  test "name", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/testify?mode=text")

    assert Repo.all(Conversation) |> length() == 0
    assert Repo.all(Chunk) |> length() == 0

    assert Repo.all(Roda.Conversations.Embedding.Embedding1024) |> length() == 0

    lv
    |> element("#text_form")
    |> render_submit(%{"text" => "michel"})

    assert_enqueued(worker: "Roda.Workers.EmbeddingWorker")
    assert_enqueued(worker: "Roda.Workers.EntityExtractionWorker")

    [conv] = Repo.all(Conversation)

    assert Repo.all(Chunk) |> length() == 1

    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :embedding)
    assert Repo.all(Roda.Conversations.Embedding.Embedding1024) |> length() == 1
    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :entity_extraction)
  end

  #
  # test "resets state when switching modes", %{conn: conn} do
  #   {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #   # Add some text content
  #   view
  #   |> element("button[phx-click='switch_mode'][phx-value-mode='text']")
  #   |> render_click()
  #
  #   render_change(view, "update_text", %{text: "Some testimony content"})
  #
  #   # Switch back to vocal
  #   view
  #   |> element("button[phx-click='switch_mode'][phx-value-mode='vocal']")
  #   |> render_click()
  #
  #   assert view.assigns.text_content == ""
  #   assert view.assigns.recording_state == :idle
  #   assert view.assigns.chunks == []
  # end
  #
  # describe "vocal mode - recording" do
  #   test "starts recording and creates conversation", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     view
  #     |> element("button[phx-click='start_recording']")
  #     |> render_click()
  #
  #     assert view.assigns.recording_state == :recording
  #     assert is_binary(view.assigns.conversation_id)
  #
  #     # Verify conversation was created
  #     conversation = Repo.get(Conversations.Conversation, view.assigns.conversation_id)
  #     assert conversation != nil
  #     assert conversation.fully_transcribed == false
  #   end
  #
  #   test "pauses recording", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Start recording
  #     view
  #     |> element("button[phx-click='start_recording']")
  #     |> render_click()
  #
  #     # Pause recording
  #     view
  #     |> element("button[phx-click='pause_recording']")
  #     |> render_click()
  #
  #     assert view.assigns.recording_state == :paused
  #   end
  #
  #   test "resumes recording after pause", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Start recording
  #     view
  #     |> element("button[phx-click='start_recording']")
  #     |> render_click()
  #
  #     # Pause recording
  #     view
  #     |> element("button[phx-click='pause_recording']")
  #     |> render_click()
  #
  #     # Resume recording
  #     view
  #     |> element("button[phx-click='resume_recording']")
  #     |> render_click()
  #
  #     assert view.assigns.recording_state == :recording
  #   end
  #
  #   test "handles chunk upload", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     render_hook(view, "chunk_uploaded", %{"path" => "org/project/conv/chunk1.webm"})
  #
  #     assert view.assigns.chunks == ["org/project/conv/chunk1.webm"]
  #
  #     render_hook(view, "chunk_uploaded", %{"path" => "org/project/conv/chunk2.webm"})
  #
  #     assert view.assigns.chunks == [
  #              "org/project/conv/chunk2.webm",
  #              "org/project/conv/chunk1.webm"
  #            ]
  #   end
  #
  #   test "handles chunk upload error", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     render_hook(view, "chunk_upload_error", %{"error" => "Network error"})
  #
  #     assert render(view) =~ "Upload error: Network error"
  #   end
  #
  #   test "handles recording error", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     render_hook(view, "recording_error", %{"error" => "Microphone not available"})
  #
  #     assert render(view) =~ "Recording error: Microphone not available"
  #   end
  # end
  #
  # describe "text mode - submission" do
  #   test "updates text content on change", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Switch to text mode
  #     view
  #     |> element("button[phx-click='switch_mode'][phx-value-mode='text']")
  #     |> render_click()
  #
  #     # Update text
  #     render_change(view, "update_text", %{text: "My testimony"})
  #
  #     assert view.assigns.text_content == "My testimony"
  #   end
  #
  #   test "submit button is disabled when text is empty", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Switch to text mode
  #     view
  #     |> element("button[phx-click='switch_mode'][phx-value-mode='text']")
  #     |> render_click()
  #
  #     assert view
  #            |> element("button[phx-click='submit_text'][disabled]")
  #            |> has_element?()
  #   end
  #
  #   test "successfully submits text testimony", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Switch to text mode
  #     view
  #     |> element("button[phx-click='switch_mode'][phx-value-mode='text']")
  #     |> render_click()
  #
  #     # Add text content
  #     text = "This is my important testimony about the event"
  #     render_change(view, "update_text", %{text: text})
  #
  #     # Submit
  #     view
  #     |> element("button[phx-click='submit_text']")
  #     |> render_click()
  #
  #     # Verify conversation was created
  #     conversation = Repo.one(Conversations.Conversation)
  #     assert conversation != nil
  #     assert conversation.fully_transcribed == true
  #
  #     # Verify chunk was created
  #     chunk = Repo.one(Conversations.Chunk)
  #     assert chunk != nil
  #     assert chunk.text == text
  #     assert chunk.position == 0
  #     assert chunk.conversation_id == conversation.id
  #     assert chunk.path == nil
  #
  #     # Verify EntityExtractionWorker was enqueued
  #     assert_enqueued(
  #       worker: Roda.Workers.EntityExtractionWorker,
  #       args: %{conversation_id: conversation.id, organization_id: view.assigns.organization_id}
  #     )
  #
  #     # Verify text content was cleared
  #     assert view.assigns.text_content == ""
  #   end
  #
  #   test "shows error when submitting empty text", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Switch to text mode
  #     view
  #     |> element("button[phx-click='switch_mode'][phx-value-mode='text']")
  #     |> render_click()
  #
  #     # Submit without text
  #     html =
  #       view
  #       |> element("button[phx-click='submit_text']")
  #       |> render_click()
  #
  #     assert html =~ "Please enter your testimony before submitting"
  #     assert Repo.aggregate(Conversations.Conversation, :count) == 0
  #   end
  #
  #   test "trims whitespace before validating", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Switch to text mode
  #     view
  #     |> element("button[phx-click='switch_mode'][phx-value-mode='text']")
  #     |> render_click()
  #
  #     # Submit whitespace only
  #     render_change(view, "update_text", %{text: "   \n\n   "})
  #
  #     html =
  #       view
  #       |> element("button[phx-click='submit_text']")
  #       |> render_click()
  #
  #     assert html =~ "Please enter your testimony before submitting"
  #     assert Repo.aggregate(Conversations.Conversation, :count) == 0
  #   end
  # end
  #
  # describe "UI rendering" do
  #   test "renders footer message", %{conn: conn} do
  #     {:ok, _view, html} = live(conn, ~p"/testify")
  #
  #     assert html =~ "All testimonies are confidential and handled with care"
  #   end
  #
  #   test "shows recording status in vocal mode", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Idle state
  #     assert view |> element("button[phx-click='start_recording']") |> has_element?()
  #
  #     # Recording state
  #     view
  #     |> element("button[phx-click='start_recording']")
  #     |> render_click()
  #
  #     assert view |> element("button[phx-click='pause_recording']") |> has_element?()
  #     assert view |> element("button[phx-click='stop_recording']") |> has_element?()
  #
  #     # Paused state
  #     view
  #     |> element("button[phx-click='pause_recording']")
  #     |> render_click()
  #
  #     assert view |> element("button[phx-click='resume_recording']") |> has_element?()
  #     assert view |> element("button[phx-click='stop_recording']") |> has_element?()
  #   end
  #
  #   test "shows chunk count when chunks are uploaded", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     render_hook(view, "chunk_uploaded", %{"path" => "chunk1.webm"})
  #     render_hook(view, "chunk_uploaded", %{"path" => "chunk2.webm"})
  #
  #     html = render(view)
  #     assert html =~ "Chunks uploaded: 2"
  #   end
  #
  #   test "renders tabs with correct active state", %{conn: conn} do
  #     {:ok, view, _html} = live(conn, ~p"/testify")
  #
  #     # Vocal tab should be active initially
  #     assert view |> element(".tab.tab-active", "Vocal") |> has_element?()
  #     refute view |> element(".tab.tab-active", "Text") |> has_element?()
  #
  #     # Switch to text
  #     view
  #     |> element("button[phx-click='switch_mode'][phx-value-mode='text']")
  #     |> render_click()
  #
  #     assert view |> element(".tab.tab-active", "Text") |> has_element?()
  #     refute view |> element(".tab.tab-active", "Vocal") |> has_element?()
  #   end
  # end
end
