defmodule Roda.Questions do
  alias Roda.Repo
  alias Roda.Organizations.Project
  alias Roda.Questions.{Question, QuestionResponse}
  import Ecto.Query

  def add(params) do
    Question.changeset(params)
    |> Repo.insert()
  end

  def list_questions_by_project_id(project_id) do
    Question
    |> where([q], q.project_id == ^project_id)
    |> Repo.all()
  end

  def get(question_id) do
    Question
    |> preload([:project])
    |> where([q], q.id == ^question_id)
    |> Repo.one()
  end

  def get_response() do
    Repo.all(QuestionResponse)
  end

  def get_response(question_id, %Date{} = begin_at, %Date{} = end_at) do
    QuestionResponse
    |> join(
      :inner,
      [q],
      question in Question,
      on: q.question_id == question.id and question.id == ^question_id
    )
    |> where(
      [q],
      q.period_start == ^begin_at and
        q.period_end == ^end_at
    )
    |> Repo.one()
  end
end
