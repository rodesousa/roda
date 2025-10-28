defmodule RodaWeb.Orga.QuestionsLive do
  use RodaWeb, :live_view

  alias Roda.{Organizations, Questions}

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    questions = Questions.list_questions_by_project_id(project_id)

    socket =
      socket
      |> assign(
        project: Organizations.get_project_by_id(project_id),
        questions: questions
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="questions"
      sidebar_type={:project}
      sidebar_params={%{orga_id: @current_scope.organization.id, project_id: @project.id}}
    >
      <.page_content>
        <div id="questions" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for  question <- @questions  do %>
            <.card
              name={question.name}
              link={
                ~p"/orgas/#{@current_scope.organization.id}/projects/#{@project.id}/questions/#{question.id}"
              }
            />
          <% end %>
          <.link
            :if={length(@questions) < 4}
            navigate={
              ~p"/orgas/#{@current_scope.organization.id}/projects/#{@project.id}/questions/new"
            }
          >
            <h3 class="text-lg font-semibold text-cohortes-black group-hover:text-cohortes-red transition-colors text-center">
              {gettext("Add a question")}
            </h3>
          </.link>
        </div>
      </.page_content>
    </.page>
    """
  end
end
