defmodule RodaWeb.Orga.QuestionLive do
  @moduledoc """
  Technical debts:
  - Jobs.list_question_jobs(question.id): several jobs can be returned (because can be failed and retried) for same id. I have to take the last one or to do be smarter
  - When a retry button appear, i need to check if other jobs are excuting before to delete them
  - If an analyse are not complete, add a button to relaunch an analyse
  Something like
  ```elixir
  if Jobs.executing?(question.id, week.period_start, week.period_end) do
  put_flash(socket, :error, gettext("A generation is already running for this period."))
  else
  Jobs.delete_question_worker(...)
  end
  ```
  - When there are erros in LLM call, the user are not notified

  Miss:
  - When a worker done, use pubsub to notify the liveview
  """
  use RodaWeb, :live_view

  alias Roda.{Questions}
  alias Roda.Citations.CitationRenderer
  alias Roda.Workers.Jobs

  @impl true
  def mount(%{"question_id" => question_id}, _session, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      with {:ok, question} <- Questions.get(scope, question_id) do
        socket
        |> assign(question: question)
        |> assign_question_response()
      else
        _ ->
          RodaWeb.UserAuth.access_denied(socket)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("generate", %{"week" => week_number}, socket) do
    %{current_scope: scope, question: question, weeks: weeks, current_week: current_week} =
      socket.assigns

    socket =
      with true <- scope.membership.role == "admin" do
        week =
          case Enum.find(weeks, &("#{&1.number}" == week_number)) do
            nil ->
              if "#{current_week.number}" == week_number,
                do: {:current_week, current_week},
                else: nil

            week ->
              {:weeks, week}
          end

        case week do
          nil ->
            socket

          {key, week} ->
            %{
              user_id: scope.user.id,
              orga_id: scope.organization.id,
              question_id: question.id,
              period_start: week.period_start,
              period_end: week.period_end
            }
            |> Roda.Workers.QuestionWorker.new()
            |> Oban.insert!()

            case key do
              :weeks ->
                weeks =
                  Enum.map(weeks, fn w ->
                    if w.number == week.number do
                      %{w | status: :executing}
                    else
                      w
                    end
                  end)

                assign(socket, :weeks, weeks)

              :current_week ->
                assign(socket, :current_week, %{current_week | status: :executing})
            end
        end
      else
        _ ->
          socket
          |> put_flash(:error, gettext("You are not authorized to create an analysis."))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("retry", %{"week" => week_number}, socket) do
    %{question: question, weeks: weeks, current_week: current_week, current_scope: scope} =
      socket.assigns

    socket =
      with true <- scope.membership.role == "admin" do
        week =
          case Enum.find(weeks, &("#{&1.number}" == week_number)) do
            nil ->
              if "#{current_week.number}" == week_number,
                do: {:current_week, current_week},
                else: nil

            week ->
              {:weeks, week}
          end

        case week do
          nil ->
            socket

          {key, week} ->
            Jobs.delete_question_worker(
              question.id,
              "#{week.period_start}",
              "#{week.period_end}"
            )

            case key do
              :weeks ->
                weeks =
                  Enum.map(weeks, fn w ->
                    if w.number == week.number do
                      %{w | status: :available}
                    else
                      w
                    end
                  end)

                assign(socket, :weeks, weeks)

              :current_week ->
                assign(socket, :current_week, %{current_week | status: :available})
            end
        end
      else
        _ ->
          socket
          |> put_flash(:error, gettext("You are not authorized to create an analysis."))
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <RodaWeb.Layouts.page flash={@flash} current="questions" scope={@current_scope}>
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={@question.name}>
          <:others>
            <li>
              <.link navigate={~p"/orgas/#{@current_scope.organization.id}/groups"}>
                <.icon name="hero-pencil-square" class="w-5 h-5" />
                {gettext("Ask")}
              </.link>
            </li>
          </:others>
        </.breadcrumb>
        <div class="mb-6">
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-3">
              <h1 class="text-3xl font-bold">{gettext("Analyses")}</h1>
            </div>
          </div>
          <div class="text-base-content/70 space-y-2">
            <p>
              {gettext(
                "Each week, AI analyzes testimonies from your group to answer this collective KPI. The analyses reveal themes, weak signals, and emerging trends from the ground up."
              )}
            </p>
            <p>
              {gettext(
                "Weekly analyses allow you to track evolution over time, compare periods, and detect meaningful shifts in your organization's lived experience."
              )}
            </p>
          </div>
        </div>

        <div
          :if={@completed_count + @current_week.conversation_count > 1}
          class="card bg-gradient-to-br from-primary/10 to-secondary/10 shadow-xl mb-6 border-2 border-primary/30 hover:shadow-2xl transition-all duration-300"
        >
          <div class="card-body p-6">
            <div class="flex items-center gap-4">
              <div class="flex-shrink-0">
                <div class="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-8 w-8 text-primary"
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
                </div>
              </div>
              <div class="flex-1">
                <h2 class="text-xl font-bold mb-1">{gettext("Theme Evolution")}</h2>
                <p class="text-base-content/70 text-sm">
                  {gettext("Visualize how themes evolve over time and identify emerging trends")}
                </p>
              </div>
              <.link
                navigate={
                  ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{@question.id}/themes"
                }
                class="btn btn-primary btn-lg gap-2"
              >
                {gettext("Explore")}
                <.icon name="hero-arrow-right" class="w-5 h-5" />
              </.link>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow-md mb-6 hover:shadow-2xl transition-all duration-300 border border-base-300">
          <div class="card-body p-5">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <h1 class="card-title text-2xl">{@question.name}</h1>
                <p class="text-base-content/70">{@question.prompt}</p>
              </div>
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
                {@generating_count} {gettext("Analysis in progress...")}
              </span>
            </div>
          </div>
        </div>

        <div :if={@current_week.conversation_count > 0} class="flex justify-center mb-6">
          <div class="w-full lg:w-1/2">
            <div class={card_class(@current_week.status)}>
              <div class="card-body">
                <div class="flex items-center justify-between">
                  <div class="space-y-1">
                    <h3 class="text-lg font-bold">
                      {gettext("Current week")} ({gettext("Week")} {@current_week.number})
                    </h3>
                    <p class="text-sm text-base-content/60">
                      {format_date_range(@current_week.period_start, @current_week.period_end)}
                    </p>
                    <p class="text-base-content/60">
                      {conversation_count_text(@current_week.conversation_count)}
                    </p>
                  </div>
                </div>

                <div class="alert alert-warning mt-2">
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

                <%= case @current_week.status do %>
                  <% :completed -> %>
                    <.button
                      navigate={
                        ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{@question.id}/show/#{@current_week.response.id}"
                      }
                      class="btn btn-success btn-block mt-2"
                    >
                      {gettext("See analysis")}
                      <.icon name="hero-arrow-right" class="w-5 h-5" />
                    </.button>
                  <% :executing -> %>
                    <div class="btn btn-block mt-2 bg-warning/10 border-warning border-2 cursor-not-allowed hover:bg-warning/10">
                      <span class="loading loading-spinner loading-md text-warning"></span>
                      <span class="text-warning font-semibold">
                        {gettext("Generation in progress...")}
                      </span>
                    </div>
                  <% :available -> %>
                    <button
                      phx-click="generate"
                      phx-value-week={@current_week.number}
                      class="btn btn-primary btn-block mt-2"
                    >
                      {gettext("Generate this analysis")}
                      <.icon name="hero-arrow-right" class="w-5 h-5" />
                    </button>
                  <% :error -> %>
                    <button
                      phx-click="retry"
                      phx-value-week={@current_week.number}
                      class="btn btn-error btn-block"
                    >
                      <.icon name="hero-arrow-path" class="w-5 h-5" />
                      {gettext("An error occurred during generation")}
                    </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Grid des semaines -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <%= for week <- @weeks do %>
            <div class={card_class(week.status)}>
              <div class="card-body">
                <!-- En-tête de semaine -->
                <div class="flex items-center justify-between">
                  <div class="space-y-1">
                    <h3 class="text-lg font-bold">
                      {gettext("Week")} {week.number}
                    </h3>
                    <p class="text-sm text-base-content/60">
                      {format_date_range(week.period_start, week.period_end)}
                    </p>
                    <p :if={Map.get(week, :conversation_count)} class="text-base-content/60">
                      {conversation_count_text(Map.get(week, :conversation_count, 0))}
                    </p>
                  </div>
                </div>
                <%= case week.status do %>
                  <% :completed -> %>
                    <.button
                      navigate={
                        ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{@question.id}/show/#{week.response.id}"
                      }
                      class="btn btn-success btn-block mt-2"
                    >
                      {gettext("See analysis")}
                      <.icon name="hero-arrow-right" class="w-5 h-5" />
                    </.button>
                  <% :executing -> %>
                    <div class="btn btn-block mt-2 bg-warning/10 border-warning border-2 cursor-not-allowed hover:bg-warning/10">
                      <span class="loading loading-spinner loading-md text-warning"></span>
                      <span class="text-warning font-semibold">
                        {gettext("Generation in progress...")}
                      </span>
                    </div>
                  <% :available -> %>
                    <button
                      phx-click="generate"
                      phx-value-week={week.number}
                      class="btn btn-primary btn-block mt-2"
                    >
                      {gettext("Generate this analysis")}
                      <.icon name="hero-arrow-right" class="w-5 h-5" />
                    </button>
                  <% :error -> %>
                    <button
                      phx-click="retry"
                      phx-value-week={week.number}
                      class="btn btn-error btn-block"
                    >
                      <.icon name="hero-arrow-path" class="w-5 h-5" />
                      {gettext("An error occurred during generation")}
                    </button>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end

  defp assign_question_response(socket) do
    %{current_scope: scope, question: question} = socket.assigns
    last_weeks = Roda.Date.last_complete_weeks(3)

    jobs =
      Jobs.list_question_jobs(question.id)
      |> Enum.reduce(%{}, fn j, acc ->
        Map.put(acc, "#{j.args["period_start"]}#{j.args["period_end"]}", j)
      end)

    weeks =
      Enum.map(last_weeks, fn {week_start, week_end} ->
        week_number =
          Roda.Date.week_number(week_start)

        status =
          case Map.get(jobs, "#{week_start}#{week_end}") do
            nil -> :available
            %{state: "executing"} -> :executing
            _ -> :error
          end

        case Questions.get_response_by_period(question.id, week_start, week_end) do
          nil ->
            conversation_count =
              Questions.count_conversations_in_period(scope, week_start, week_end)

            if conversation_count > 0 do
              %{
                number: week_number,
                period_start: week_start,
                period_end: week_end,
                status: status,
                response: nil,
                conversation_count: conversation_count
              }
            else
              # No conversations, don't show this week
              nil
            end

          response ->
            status =
              if response.narrative_response && response.narrative_response != "" do
                :completed
              else
                :executing
              end

            week_data = %{
              number: week_number,
              period_start: week_start,
              period_end: week_end,
              status: status,
              response: response
            }

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

    # Calculate current week
    current_week = calculate_current_week(scope, question, jobs)

    completed_count = Enum.count(weeks, &(&1.status == :completed))
    total_weeks = length(weeks)
    generating_count = Enum.count(weeks, &(&1.status == :executing))

    socket
    |> assign(:weeks, weeks)
    |> assign(:current_week, current_week)
    |> assign(:completed_count, completed_count)
    |> assign(:total_weeks, total_weeks)
    |> assign(:generating_count, generating_count)
  end

  defp calculate_current_week(scope, question, jobs) do
    today = Date.utc_today()
    # Get the start of the current week (Monday)
    days_since_monday = Date.day_of_week(today) - 1
    week_start = Date.add(today, -days_since_monday)
    # Week ends on Sunday
    week_end = Date.add(week_start, 6)

    week_number = Roda.Date.week_number(week_start)

    conversation_count = Questions.count_conversations_in_period(scope, week_start, week_end)

    status =
      case Map.get(jobs, "#{week_start}#{week_end}") do
        nil -> :available
        %{state: "executing"} -> :executing
        _ -> :error
      end

    case Questions.get_response_by_period(question.id, week_start, week_end) do
      nil ->
        %{
          number: week_number,
          period_start: week_start,
          period_end: week_end,
          status: status,
          response: nil,
          conversation_count: conversation_count
        }

      response ->
        status =
          if response.narrative_response && response.narrative_response != "" do
            :completed
          else
            :executing
          end

        %{
          number: week_number,
          period_start: week_start,
          period_end: week_end,
          status: status,
          response: response,
          conversation_count: conversation_count
        }
    end
  end

  defp card_class(:completed), do: "card bg-base-100 shadow-lg border-2 border-success"
  defp card_class(:error), do: "card bg-base-100 shadow-lg border-2 border-error"
  defp card_class(:executing), do: "card bg-base-100 shadow-lg border-2 border-warning"
  defp card_class(:available), do: "card bg-base-100 shadow-xl border-2 border-primary"

  defp format_date_range(period_start, period_end) do
    start_str = Calendar.strftime(period_start, "%-d %B")
    end_str = Calendar.strftime(period_end, "%-d %B %Y")
    "#{start_str} - #{end_str}"
  end

  defp conversation_count_text(1), do: gettext("1 analyzed conversation")

  defp conversation_count_text(count),
    do: gettext("%{count} testimonies", count: count)
end
