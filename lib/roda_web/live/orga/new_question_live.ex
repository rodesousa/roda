defmodule RodaWeb.Orga.NewQuestionLive do
  use RodaWeb, :live_view
  alias Roda.{Analyses}
  alias Roda.Questions.Analyse
  alias Roda.{Organizations, Questions}
  alias Roda.Questions.Question
  alias Roda.Repo

  def mount(%{"orga_id" => orga_id, "project_id" => project_id}, _session, socket) do
    socket =
      socket
      |> assign(
        project: Organizations.get_project_by_id(project_id),
        orga: Organizations.get_orga_by_id(orga_id),
        question_form: to_form(Question.changeset(%{}))
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("create_question", %{"question" => params}, socket) do
    ass = socket.assigns
    params = Map.put(params, "project_id", ass.project.id)

    socket =
      case Questions.add(params) do
        {:ok, question} ->
          push_navigate(socket,
            to: ~p"/orgas/#{ass.orga.id}/projects/#{ass.project.id}/questions"
          )

        {:error, changeset} ->
          socket
          |> assign(question_form: to_form(changeset))
      end

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
        <.form :let={f} for={@question_form} phx-submit="create_question">
          <div class="flex-col space-y-4">
            <.input field={f[:name]} label={gettext("Question name")} />
            <.input type="textarea" field={f[:prompt]} label={gettext("Question prompt")} />
          </div>
          <.button>
            {gettext("Create")}
          </.button>
        </.form>
      </.page_content>
    </.page>
    """
  end
end
