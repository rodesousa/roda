defmodule RodaWeb.Orga.QuestionLive do
  use RodaWeb, :live_view

  alias Roda.{Organizations, Questions, Date}
  alias Roda.Citations.CitationRenderer

  @impl true
  def mount(
        %{"orga_id" => orga_id, "project_id" => project_id, "question_id" => question_id},
        _session,
        socket
      ) do
    socket =
      socket
      |> assign(
        project: Organizations.get_project_by_id(project_id),
        orga: Organizations.get_orga_by_id(orga_id),
        question: Questions.get(question_id)
      )
      |> assign_question_response()

    {:ok, socket}
  end

  @impl true
  def handle_event("generate", _, socket) do
    ass = socket.assigns

    %{question_id: ass.question.id}
    |> Roda.Workers.QuestionWorker.new()
    |> Oban.insert!()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="questions"
      sidebar_type={:project}
      sidebar_params={%{orga_id: @orga.id, project_id: @project.id}}
    >
      <.page_content>
        <div id="questions" class="flex flex-col space-y-2">
          <div>
            {@question.name}
          </div>
          <div>
            {@question.prompt}
          </div>
        </div>
        <div class="mt-6">
          <.button phx-click="generate">
            {gettext("Generate !")}
          </.button>
        </div>

        <div :if={@response} class="mt-8">
          <div class="card bg-base-100 shadow-lg border border-base-300">
            <div class="card-body">
              <h2 class="card-title text-xl mb-4">{gettext("Analysis Results")}</h2>

              <div
                class="prose prose-lg max-w-none"
                phx-hook="MarkdownCitations"
                id="markdown-content"
                data-content={@response.response_text}
                data-citation-map={@citation_map}
                data-modals-html={@modals_html}
              >
              </div>
            </div>
          </div>
        </div>
      </.page_content>
    </.page>
    """
  end

  def assign_question_response(socket) do
    begin_at = Date.beginning_of_week()
    end_at = Date.end_of_week()
    ass = socket.assigns

    response =
      case Questions.get_response(ass.project.id, begin_at, end_at) do
        nil ->
          assign(socket,
            response: nil,
            modals_html: nil,
            citation_map: nil
          )

        response ->
          ass = socket.assigns

          conversations =
            Roda.Projects.get_conversations(ass.project.id)
            |> Enum.flat_map(fn %{chunks: chunks} ->
              chunks
              |> Enum.map(fn %{text: text, id: id} ->
                %{id: id, text: text}
              end)
            end)

          %{modals_html: modals_html, citation_map: citation_map} =
            CitationRenderer.prepare_citations(response.response_text, conversations)

          assign(socket,
            response: response,
            modals_html: modals_html,
            citation_map: Jason.encode!(citation_map)
          )
      end
  end
end
