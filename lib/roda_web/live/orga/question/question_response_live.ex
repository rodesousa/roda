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
    %{current_scope: scope} = socket.assigns

    socket =
      with {:ok, question} <- Questions.get(scope, question_id) do
        socket
        |> assign(
          question: question,
          complete: :ok
        )
        |> assign_question_response(question_response_id)
        |> set_response_complete()
      else
        _ ->
          RodaWeb.UserAuth.access_denied(socket)
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <RodaWeb.Layouts.page
      flash={@flash}
      current="questions"
      scope={@current_scope}
    >
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={@question.name}>
          <:others>
            <li>
              <.link navigate={
                ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project}/questions"
              }>
                <.icon name="hero-pencil-square" class="w-5 h-5" />
                {gettext("Ask")}
              </.link>
            </li>
          </:others>
        </.breadcrumb>

        <div :if={@complete == :warn} class="alert alert-warning mb-6">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="stroke-current shrink-0 h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          <span class="text-sm">
            {gettext(
              "Warning: This analysis only includes testimonies received so far this week. Any new messages arriving later will not be included in this analysis."
            )}
          </span>
        </div>

        <div :if={@complete == :error} class="alert alert-error mb-6">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="stroke-current shrink-0 h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <span class="text-sm">
            {gettext("Error: Not all testimonies could be included in this analysis.")}
          </span>
        </div>

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
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end

  defp assign_question_response(socket, question_response_id) do
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

  defp set_response_complete(socket) do
    %{current_scope: scope} = ass = socket.assigns

    start? = ass.response.period_start == Date.beginning_of_week(Date.utc_today())
    end? = ass.response.period_end == Date.end_of_week(Date.utc_today())

    if start? && end? do
      assign(socket, complete: :warn)
    else
      case Questions.set_response_complete(scope, ass.response) do
        {:ok, _} -> socket
        :error -> assign(socket, complete: :error)
      end
    end
  end
end
