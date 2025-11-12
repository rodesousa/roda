defmodule RodaWeb.Orga.QuestionsLive do
  @moduledoc """
  Technical debt:
  - Cannot archive
  """
  use RodaWeb, :live_view

  alias Roda.Questions.Question
  alias Roda.{Questions}

  @impl true
  def mount(_, _session, socket) do
    socket =
      socket
      |> assign_questions()
      |> assign_question_form()

    {:ok, socket}
  end

  defp assign_question_form(socket) do
    socket
    |> assign(question_form: to_form(Question.changeset(%{})))
  end

  defp assign_questions(socket) do
    %{current_scope: scope} = socket.assigns

    socket
    |> assign_async(:questions, fn ->
      questions = Questions.list_questions_by_project_id(scope)
      {:ok, %{questions: questions}}
    end)
  end

  @impl true
  def handle_event("question:creation", params, socket) do
    %{current_scope: scope} = socket.assigns

    socket =
      case Questions.add_question(scope, params["question"]) do
        {:ok, _} ->
          socket
          |> assign_questions()
          |> assign_question_form()
          |> push_event("close:modal", %{id: "question-creation"})

        changeset ->
          socket
          |> assign(question_form: to_form(Map.put(changeset, :action, :validate)))
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.modal id="question-creation">
      <.question_creation form={@question_form} />
    </.modal>
    <RodaWeb.Layouts.page
      flash={@flash}
      current="questions"
      scope={@current_scope}
    >
      <RodaWeb.Layouts.page_content>
        <.breadcrumb scope={@current_scope} i={gettext("Collective KPIs")} />
        <div class="mb-6">
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-3">
              <h1 class="text-3xl font-bold">{gettext("Collective KPIs")}</h1>
            </div>
            <.button
              :if={@questions.ok? && length(@questions.result) < 4}
              phx-click={show_modal("question-creation")}
              class="btn btn-primary gap-2"
            >
              <.icon name="hero-plus" />
              {gettext("New KPI")}
            </.button>
          </div>
          <div class="text-base-content/70 space-y-4">
            <p>
              {gettext(
                "Here, you can formulate collective questions, called collective KPIs. They're not meant to manage from the top down, but to listen to what truly matters within the organization."
              )}
            </p>
            <p>
              {gettext(
                "Each week, the AI analyzes shared testimonies (text or voice) to detect themes, weak signals, and emerging trends. The questions raised by the community then become collective markers — they reveal the issues that arise from the ground up, rather than those decided by managers."
              )}
            </p>
            <p>
              {gettext(
                "The goal: to turn lived experience into a shared compass, and make governance more sensitive, fair, and collective."
              )}
            </p>
          </div>
        </div>
        <div :if={@questions.ok?} id="questions" class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <%= for  question <- @questions.result do %>
            <.question_card
              question={question}
              count={question.count_responses}
              view_link={
                ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{question.id}"
              }
            />
          <% end %>
        </div>
      </RodaWeb.Layouts.page_content>
    </RodaWeb.Layouts.page>
    """
  end

  defp question_creation(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="text-xl font-bold">{gettext("Create new KPI")}</h2>

      <p class="text-sm text-base-content/70">
        {gettext("Groups help you organize and track testimonies from specific communities.")}
      </p>

      <.form id="question-form" for={@form} phx-submit="question:creation" class="space-y-4">
        <.input
          field={@form[:name]}
          label={gettext("Group name")}
          placeholder={gettext("e.g., Marketing Team 2024")}
          required={true}
        />

        <div class="flex justify-end gap-2 pt-4">
          <.button phx-click={hide_modal("question-creation")} type="button" class="btn btn-ghost">
            {gettext("Cancel")}
          </.button>
          <.button type="submit" class="btn btn-primary">
            {gettext("Create KPI")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
