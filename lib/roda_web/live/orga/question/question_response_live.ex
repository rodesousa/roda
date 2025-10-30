defmodule RodaWeb.Orga.Question.QuestionResponseLive do
  use RodaWeb, :live_view

  alias Roda.{Questions}
  alias Roda.Citations.CitationRenderer

  @impl true
  def mount(
        %{"question_id" => question_id, "question_response_id" => question_response_id},
        _session,
        socket
      ) do
    socket =
      with %{current_scope: scope} <- socket.assigns,
           {:ok, question} <- Questions.get(scope, question_id) do
        socket
        |> assign(question: question)
        |> assign_question_response(question_response_id)
      else
        {_, socket} ->
          RodaWeb.UserAuth.access_denied(socket)
          socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="questions"
      scope={@current_scope}
    >
      <.page_content>
        <div class="card bg-base-100 shadow-lg border border-base-300">
          <div class="card-body">
            <div
              class="prose prose-lg max-w-none"
              phx-hook="MarkdownCitations"
              id="markdown-content"
              data-content={@response.narrative_response}
              data-citation-map={@citation_map}
              data-modals-html={@modals_html}
            >
            </div>
          </div>
        </div>
      </.page_content>
    </.page>
    """
  end

  def assign_question_response(socket, question_response_id) do
    %{current_scope: scope} = ass = socket.assigns

    case Questions.get_response_by_id(question_response_id, ass.question.id) do
      {:ok, response} ->
        conversations =
          Roda.Projects.get_conversations(scope.project.id)
          |> Enum.flat_map(fn %{chunks: chunks} ->
            chunks
            |> Enum.map(fn %{text: text, id: id} ->
              %{id: id, text: text}
            end)
          end)

        %{modals_html: modals_html, citation_map: citation_map} =
          CitationRenderer.prepare_citations(response.narrative_response, conversations)

        assign(socket,
          response: response,
          modals_html: modals_html,
          citation_map: Jason.encode!(citation_map)
        )
    end
  end
end
