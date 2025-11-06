defmodule RodaWeb.Orga.Question.ThemesEvolutionLive do
  use RodaWeb, :live_view

  alias Roda.Questions

  @impl true
  def mount(%{"question_id" => question_id}, _session, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      with {:ok, question} <- Questions.get(scope, question_id) do
        socket
        |> assign(question: question)
        |> load_themes_evolution()
        |> select_last_week()
      else
        _ ->
          RodaWeb.UserAuth.access_denied(socket)
          socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <RodaWeb.Layouts.page current="questions" scope={@current_scope} flash={@flash}>
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Evolution")}>
          <:others>
            <li>
              <.link navigate={~p"/orgas/#{@current_scope.organization.id}/groups"}>
                <.icon name="hero-pencil-square" class="w-5 h-5" />
                {gettext("Ask")}
              </.link>
            </li>
            <li>
              <.link navigate={
                ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{@question.id}"
              }>
                {@question.name}
              </.link>
            </li>
          </:others>
        </.breadcrumb>
        <!-- Header -->
        <div class="mb-6">
          <h1 class="text-3xl font-bold mt-4">{gettext("Theme evolution")}</h1>
          <p class="text-base-content/70 mt-2">
            {@question.prompt}
          </p>
        </div>
        <!-- Main layout: sidebar + content -->
        <div class="flex gap-6">
          <!-- Sidebar: Liste des thèmes -->
          <div class="w-64 flex-shrink-0">
            <div class="card bg-base-100 shadow-lg border border-base-300 sticky top-4">
              <div class="card-body p-4">
                <h3 class="font-bold text-sm mb-3">
                  {gettext("Themes")} ({length(@all_themes)})
                </h3>

                <div class="space-y-1 max-h-[600px] overflow-y-auto">
                  <%= for theme <- @all_themes do %>
                    <button
                      phx-click="select_theme"
                      phx-value-hashed_name={theme.hashed_name}
                      class={theme_button_class(@selection_mode, @selected_theme, theme.hashed_name)}
                    >
                      <span class="text-lg">{sentiment_emoji(theme.sentiment)}</span>
                      <span class="text-sm text-left flex-1 truncate">{theme.name}</span>
                    </button>
                  <% end %>
                </div>

                <button
                  :if={false && @selection_mode == :theme}
                  phx-click="clear_theme_selection"
                  class="btn btn-ghost btn-sm w-full mt-3"
                >
                  {gettext("← Back to weeks")}
                </button>
              </div>
            </div>
          </div>
          <!-- Main content -->
          <div class="flex-1">
            <div
              id="timeline"
              class="card bg-base-100 shadow-lg border border-base-300 mb-6"
            >
              <div class="card-body p-6">
                <h3 class="font-bold mb-4">
                  <%= if @selection_mode == :week do %>
                    {gettext("Timeline (majority sentiment)")}
                  <% else %>
                    {gettext("Theme presence")}
                  <% end %>
                </h3>
                <div class="flex overflow-x-auto gap-3 items-center max-w-md md:max-w-xl lg:max-w-2xl xl:max-w-4xl h-32 px-2">
                  <%= for week <- @weeks do %>
                    <button
                      phx-click="select_week"
                      phx-value-number={week.number}
                      class={"flex-shrink-0 " <> week_card_class(@selection_mode, @selected_week, @selected_theme_data, week)}
                    >
                      <div class="font-bold text-lg">S{week.number}</div>
                      <div class="text-xs opacity-70">
                        {Calendar.strftime(week.period_start, "%-d/%m")}
                      </div>
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
            <!-- Content area -->
            <div class="space-y-6">
              <%= if @selection_mode == :week do %>
                <!-- Mode: Semaine sélectionnée -->
                <div class="alert alert-info">
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
                    {gettext("Week")} {@selected_week} - {length(@display_content)} {gettext(
                      "identified theme(s)"
                    )}
                  </span>
                </div>

                <%= for theme <- @display_content do %>
                  <div
                    class="card bg-base-100 shadow-lg border-2"
                    class={theme_card_border(theme["sentiment"])}
                  >
                    <div class="card-body">
                      <div class="flex items-start justify-between mb-3">
                        <div class="flex-1">
                          <h3 class="text-xl font-bold flex items-center gap-2">
                            {sentiment_emoji(theme["sentiment"])}
                            {theme["name"]}
                          </h3>
                          <p class="text-xs text-base-content/50 font-mono mt-1">
                            {theme["hashed_name"]}
                          </p>
                        </div>
                        <div class={sentiment_badge_class(theme["sentiment"])}>
                          {String.capitalize(theme["sentiment"])}
                        </div>
                      </div>

                      <div
                        phx-hook="Markdown"
                        id={"theme-desc-#{theme["hashed_name"]}"}
                        class="prose prose-sm max-w-none text-base-content/80"
                        data-content={theme["description"]}
                      >
                      </div>
                    </div>
                  </div>
                <% end %>
              <% else %>
                <!-- Mode: Thème sélectionné -->
                <div class="alert alert-info">
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
                    {gettext("Present in")} {length(@selected_theme_data.present_in_weeks)}/{length(
                      @weeks
                    )} {gettext("weeks")}
                  </span>
                </div>

                <div
                  class="card bg-base-100 shadow-lg border-2"
                  class={theme_card_border(@selected_theme_data.sentiment)}
                >
                  <div class="card-body">
                    <div class="flex items-start justify-between mb-3">
                      <div class="flex-1">
                        <h3 class="text-2xl font-bold flex items-center gap-2">
                          {sentiment_emoji(@selected_theme_data.sentiment)}
                          {@selected_theme_data.name}
                        </h3>
                        <p class="text-xs text-base-content/50 font-mono mt-1">
                          {@selected_theme_data.hashed_name}
                        </p>
                      </div>
                      <div class={sentiment_badge_class(@selected_theme_data.sentiment)}>
                        {String.capitalize(@selected_theme_data.sentiment)}
                      </div>
                    </div>

                    <div class="divider"></div>

                    <div class="space-y-4">
                      <%= for week_desc <- @selected_theme_data.week_descriptions do %>
                        <div>
                          <h4 class="font-semibold text-sm mb-2">
                            S{week_desc.week_number}
                          </h4>
                          <div
                            phx-hook="Markdown"
                            id={"theme-week-desc-#{week_desc.week_number}"}
                            class="prose prose-sm max-w-none text-base-content/80"
                            data-content={week_desc.description}
                          >
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end

  @impl true
  def handle_event("select_week", %{"number" => number_str}, socket) do
    number = String.to_integer(number_str)
    week = Enum.find(socket.assigns.weeks, &(&1.number == number))

    socket =
      socket
      |> assign(:selection_mode, :week)
      |> assign(:selected_week, number)
      |> assign(:selected_theme, nil)
      |> assign(:display_content, week.themes)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_theme", %{"hashed_name" => hashed_name}, socket) do
    theme_data = Enum.find(socket.assigns.all_themes, &(&1.hashed_name == hashed_name))

    socket =
      socket
      |> assign(:selection_mode, :theme)
      |> assign(:selected_theme, hashed_name)
      |> assign(:selected_theme_data, theme_data)
      |> assign(:display_content, [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_theme_selection", _, socket) do
    socket = select_last_week(socket)
    {:noreply, socket}
  end

  defp load_themes_evolution(socket) do
    %{question: question} = socket.assigns

    # Get all completed responses for this question
    responses = Questions.list_responses_by_question(question.id)

    # Extract weeks info with themes
    weeks =
      responses
      |> Enum.filter(&(&1.narrative_response && &1.narrative_response != ""))
      |> Enum.map(fn response ->
        themes = get_themes_from_response(response)
        sentiment_majority = calculate_sentiment_majority(themes)

        %{
          number: Roda.Date.week_number(response.period_start),
          period_start: response.period_start,
          period_end: response.period_end,
          themes: themes,
          sentiment_majority: sentiment_majority
        }
      end)
      |> Enum.sort_by(& &1.number, :desc)

    # Extract all unique themes with their data
    all_themes =
      weeks
      |> Enum.flat_map(& &1.themes)
      |> Enum.group_by(& &1["hashed_name"])
      |> Enum.map(fn {hashed_name, theme_occurrences} ->
        # Sort by week to get the latest
        sorted_occurrences = Enum.sort_by(theme_occurrences, & &1["week_number"], :desc)
        latest = hd(sorted_occurrences)

        # Find weeks where this theme is present with their descriptions
        week_descriptions =
          weeks
          |> Enum.filter(fn week ->
            Enum.any?(week.themes, &(&1["hashed_name"] == hashed_name))
          end)
          |> Enum.map(fn week ->
            theme_in_week = Enum.find(week.themes, &(&1["hashed_name"] == hashed_name))

            %{
              week_number: week.number,
              description: theme_in_week["description"]
            }
          end)

        presence_weeks = Enum.map(week_descriptions, & &1.week_number)

        %{
          hashed_name: hashed_name,
          name: latest["name"],
          sentiment: latest["sentiment"],
          description: latest["description"],
          present_in_weeks: presence_weeks,
          week_descriptions: week_descriptions
        }
      end)
      |> Enum.sort_by(&length(&1.present_in_weeks), :desc)

    socket
    |> assign(:weeks, weeks)
    |> assign(:all_themes, all_themes)
    |> assign(:selection_mode, :week)
    |> assign(:selected_week, nil)
    |> assign(:selected_theme, nil)
    |> assign(:selected_theme_data, nil)
    |> assign(:display_content, [])
  end

  defp select_last_week(socket) do
    case socket.assigns.weeks do
      [last_week | _] ->
        socket
        |> assign(:selection_mode, :week)
        |> assign(:selected_week, last_week.number)
        |> assign(:selected_theme, nil)
        |> assign(:display_content, last_week.themes)

      [] ->
        socket
    end
  end

  defp get_themes_from_response(response) do
    case response.structured_response do
      %{"themes" => themes} when is_list(themes) ->
        # Add week info to each theme for sorting later
        Enum.map(themes, fn theme ->
          Map.put(theme, "week_number", Roda.Date.week_number(response.period_start))
        end)

      _ ->
        []
    end
  end

  defp calculate_sentiment_majority(themes) do
    themes
    |> Enum.frequencies_by(& &1["sentiment"])
    |> Enum.max_by(fn {_sentiment, count} -> count end, fn -> {nil, 0} end)
    |> elem(0)
  end

  # Helper functions for styling

  defp theme_button_class(:theme, selected_theme, hashed_name)
       when selected_theme == hashed_name do
    "btn btn-sm btn-primary w-full justify-start gap-2 normal-case font-normal"
  end

  defp theme_button_class(_, _, _) do
    "btn btn-sm btn-ghost w-full justify-start gap-2 normal-case font-normal"
  end

  defp week_card_class(:week, selected_week, _, week) when selected_week == week.number do
    base =
      "flex flex-col items-center justify-center w-20 h-20 rounded-xl border-4 cursor-pointer transition-all"

    # Semaine sélectionnée = neutre
    base <> " border-base-300 bg-base-200 shadow-lg transform scale-110"
  end

  defp week_card_class(:week, _, _, _week) do
    "flex flex-col items-center justify-center w-20 h-20 rounded-xl border-2 cursor-pointer transition-all hover:scale-105 border-base-300 bg-base-200 text-base-content/30 opacity-50"
  end

  defp week_card_class(:theme, _, selected_theme_data, week) do
    base =
      "flex flex-col items-center justify-center w-20 h-20 rounded-xl border-2 cursor-pointer transition-all"

    # Trouver le thème dans cette semaine pour obtenir son sentiment
    theme_in_week =
      Enum.find(week.themes, &(&1["hashed_name"] == selected_theme_data.hashed_name))

    if theme_in_week do
      # Thème présent : afficher la couleur du sentiment
      sentiment = theme_in_week["sentiment"]
      border_color = sentiment_border_color(sentiment)
      bg_color = sentiment_bg_color(sentiment)
      base <> " #{border_color} #{bg_color} hover:scale-105"
    else
      # Thème absent : ghost
      base <> " border-base-300 bg-base-200 text-base-content/30 opacity-50"
    end
  end

  defp sentiment_border_color("positif"), do: "border-success"
  defp sentiment_border_color("negatif"), do: "border-error"
  defp sentiment_border_color("neutre"), do: "border-base-300"
  defp sentiment_border_color(_), do: "border-base-300"

  defp sentiment_bg_color("positif"), do: "bg-success/10"
  defp sentiment_bg_color("negatif"), do: "bg-error/10"
  defp sentiment_bg_color("neutre"), do: "bg-base-200"
  defp sentiment_bg_color(_), do: "bg-base-200"

  defp theme_card_border("positif"), do: "border-success/30"
  defp theme_card_border("negatif"), do: "border-error/30"
  defp theme_card_border("neutre"), do: "border-base-300"
  defp theme_card_border(_), do: "border-base-300"

  defp sentiment_emoji("positif"), do: "🟢"
  defp sentiment_emoji("negatif"), do: "🔴"
  defp sentiment_emoji("neutre"), do: "⚪"
  defp sentiment_emoji(_), do: "⚪"

  defp sentiment_badge_class("positif"), do: "badge badge-success badge-lg gap-2"
  defp sentiment_badge_class("negatif"), do: "badge badge-error badge-lg gap-2"
  defp sentiment_badge_class("neutre"), do: "badge badge-ghost badge-lg gap-2"
  defp sentiment_badge_class(_), do: "badge badge-ghost badge-lg gap-2"
end
