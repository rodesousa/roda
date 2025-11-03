defmodule RodaWeb.Orga.QuestionLive do
  use RodaWeb, :live_view

  alias Roda.{Questions}
  alias Roda.Citations.CitationRenderer

  @impl true
  def mount(%{"question_id" => question_id}, _session, socket) do
    socket =
      with %{current_scope: scope} <- socket.assigns,
           {:ok, question} <- Questions.get(scope, question_id) do
        socket
        |> assign(question: question)
        |> assign_question_response()
      else
        {_, socket} ->
          RodaWeb.UserAuth.access_denied(socket)
          socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("generate", %{"week" => week_number}, socket) do
    %{current_scope: scope, question: question, weeks: weeks} = socket.assigns

    week = Enum.find(weeks, &(to_string(&1.number) == week_number))

    %{
      user_id: scope.user.id,
      orga_id: scope.organization.id,
      question_id: question.id,
      period_start: week.start_date,
      period_end: week.end_date
    }
    |> Roda.Workers.QuestionWorker.new()
    |> Oban.insert!()

    #
    # # Mettre à jour le statut de cette semaine à "generating"
    # updated_weeks =
    #   Enum.map(weeks, fn w ->
    #     if w.number == week.number do
    #       %{w | status: :generating}
    #     else
    #       w
    #     end
    #   end)
    #
    # socket = assign(socket, :weeks, updated_weeks)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="questions" scope={@current_scope}>
      <.page_content>
        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <h1 class="card-title text-2xl">{@question.name}</h1>
                <p class="text-base-content/70">{@question.prompt}</p>
              </div>

              <.link
                :if={@completed_count > 1}
                navigate={
                  ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{@question.id}/themes"
                }
                class="btn btn-outline btn-sm gap-2"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
                {gettext("Évolution des thèmes")}
              </.link>
            </div>
            
    <!-- Progress global -->
            <div class="flex items-center gap-4 mt-4">
              <progress
                class="progress progress-primary w-full"
                value={@completed_count}
                max={@total_weeks}
              >
              </progress>
              <span class="text-sm font-medium">
                {@completed_count}/{@total_weeks} {gettext("analyses complétées")}
              </span>
            </div>

            <div :if={@generating_count > 0} class="alert alert-info mt-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="stroke-current shrink-0 w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
              <span>
                {@generating_count} {gettext("analyse(s) en cours de génération")}
              </span>
            </div>
          </div>
        </div>
        <!-- Timeline des semaines -->
        <ul class="timeline timeline-vertical timeline-snap-icon">
          <%= for week <- @weeks do %>
            <li>
              <!-- Icône selon statut -->

              <div class="timeline-middle"></div>

              <div class={timeline_end_class(week)}>
                <div class={card_class(week.status)}>
                  <div class="card-body">
                    <!-- En-tête de semaine -->
                    <div class="flex items-center justify-between">
                      <div>
                        <h3 class="text-lg font-bold">
                          {gettext("Semaine")} {week.number}
                        </h3>
                        <p class="text-sm text-base-content/60">
                          {format_date_range(week.start_date, week.end_date)}
                        </p>
                      </div>
                    </div>
                    <!-- Contenu selon statut -->
                    <%= case week.status do %>
                      <% :completed -> %>
                        <.button navigate={
                          ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{@question.id}/show/#{week.response.id}"
                        }>
                          {gettext("See analayse")}
                        </.button>
                      <% :generating -> %>
                        <div class="flex items-center gap-3 mt-4 p-4 bg-info/10 rounded-lg">
                          <span class="loading loading-spinner loading-md text-info"></span>
                          <span class="text-info font-medium">
                            {gettext("Génération en cours...")}
                          </span>
                        </div>
                      <% :available -> %>
                        <button
                          phx-click="generate"
                          phx-value-week={week.number}
                          class="btn btn-primary btn-block mt-4"
                        >
                          {gettext("Générer cette analyse")}
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            class="h-5 w-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M13 7l5 5m0 0l-5 5m5-5H6"
                            />
                          </svg>
                        </button>
                    <% end %>
                  </div>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </.page_content>
    </.page>
    """
  end

  def assign_question_response(socket) do
    %{current_scope: scope, question: question} = socket.assigns

    last_weeks = Roda.Date.last_complete_weeks(3)

    # Build weeks list with their status
    weeks =
      Enum.map(last_weeks, fn {week_start, week_end} ->
        week_number = Roda.Date.week_number(week_start)

        # Check if question_response exists for this period
        case Questions.get_response_by_period(question.id, week_start, week_end) do
          nil ->
            # No response yet, check if conversations exist
            conversation_count =
              Questions.count_conversations_in_period(scope, week_start, week_end)

            if conversation_count > 0 do
              %{
                number: week_number,
                start_date: week_start,
                end_date: week_end,
                status: :available,
                response: nil,
                conversation_count: conversation_count
              }
            else
              # No conversations, don't show this week
              nil
            end

          response ->
            # Response exists, determine status based on narrative_response
            status =
              if response.narrative_response && response.narrative_response != "" do
                :completed
              else
                :generating
              end

            week_data = %{
              number: week_number,
              start_date: week_start,
              end_date: week_end,
              status: status,
              response: response
            }

            # If completed, prepare citations
            if status == :completed do
              conversations =
                Roda.Organizations.get_conversations(
                  scope,
                  NaiveDateTime.new!(week_start, ~T[00:00:00]),
                  NaiveDateTime.new!(week_end, ~T[23:59:59])
                )
                |> Enum.flat_map(fn %{chunks: chunks} ->
                  Enum.map(chunks, fn chunk -> %{id: chunk.id, text: chunk.text} end)
                end)

              %{modals_html: modals_html, citation_map: citation_map} =
                CitationRenderer.prepare_citations(response.narrative_response, conversations)

              Map.merge(week_data, %{
                citation_map: Jason.encode!(citation_map),
                modals_html: modals_html
              })
            else
              week_data
            end
        end
      end)
      |> Enum.reject(&is_nil/1)

    completed_count = Enum.count(weeks, &(&1.status == :completed))
    total_weeks = length(weeks)
    generating_count = Enum.count(weeks, &(&1.status == :generating))

    socket
    |> assign(:weeks, weeks)
    |> assign(:completed_count, completed_count)
    |> assign(:total_weeks, total_weeks)
    |> assign(:generating_count, generating_count)
  end

  defp timeline_end_class(%{status: :available}), do: "timeline-end mb-10 w-full"
  defp timeline_end_class(_), do: "timeline-end mb-10 w-full opacity-90"

  defp card_class(:completed), do: "card bg-base-100 shadow-lg border-2 border-success/20"
  defp card_class(:generating), do: "card bg-base-100 shadow-lg border-2 border-info/20"
  defp card_class(:available), do: "card bg-base-100 shadow-xl border-2 border-primary"

  defp format_date_range(start_date, end_date) do
    start_str = Calendar.strftime(start_date, "%-d %B")
    end_str = Calendar.strftime(end_date, "%-d %B %Y")
    "#{start_str} - #{end_str}"
  end
end
