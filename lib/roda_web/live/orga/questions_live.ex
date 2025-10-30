defmodule RodaWeb.Orga.QuestionsLive do
  use RodaWeb, :live_view

  alias Roda.{Questions}

  @impl true
  def mount(_, _session, socket) do
    %{current_scope: scope} = socket.assigns
    questions = Questions.list_questions_by_project_id(scope.project.id)

    socket =
      socket
      |> assign(questions: questions)

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
        <div id="questions" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for  question <- @questions  do %>
            <.card
              name={question.name}
              link={
                ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/#{question.id}"
              }
            />
          <% end %>
          <.link
            :if={length(@questions) < 4}
            navigate={
              ~p"/orgas/#{@current_scope.organization.id}/projects/#{@current_scope.project.id}/questions/new"
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
