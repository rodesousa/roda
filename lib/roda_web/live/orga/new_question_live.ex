defmodule RodaWeb.Orga.NewQuestionLive do
  use RodaWeb, :live_view
  alias Roda.{Questions}
  alias Roda.Questions.Question

  @impl true
  def mount(_, _session, socket) do
    socket =
      socket
      |> assign(question_form: to_form(Question.changeset(%{})))

    {:ok, socket}
  end

  @impl true
  def handle_event("create_question", %{"question" => params}, socket) do
    %{current_scope: scope} = socket.assigns
    params = Map.put(params, "project_id", scope.project.id)

    socket =
      case Questions.add(params) do
        {:ok, question} ->
          push_navigate(socket,
            to: ~p"/orgas/#{scope.organization.id}/projects/#{scope.project.id}/questions"
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
      scope={@current_scope}
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
