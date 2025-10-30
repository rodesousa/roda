defmodule Roda.Questions do
  alias Roda.Repo
  alias Roda.Questions.{Question, QuestionResponse}
  alias Roda.Accounts.Scope
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

  def get(%Scope{} = s, question_id) do
    Question
    |> where([q], q.id == ^question_id and q.project_id == ^s.project.id)
    |> preload([:project])
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      question -> {:ok, question}
    end
  end

  def get(question_id) do
    Question
    |> preload([:project])
    |> where([q], q.id == ^question_id)
    |> Repo.one()
  end

  def get_response_by_id(question_response_id, question_id) do
    QuestionResponse
    |> where([qr], qr.id == ^question_response_id and qr.question_id == ^question_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      qr -> {:ok, qr}
    end
  end

  def get_response_by_question(question_id, %Date{} = begin_at, %Date{} = end_at) do
    QuestionResponse
    |> where(
      [qr],
      qr.question_id == ^question_id and
        qr.period_start == ^begin_at and
        qr.period_end == ^end_at
    )
    |> Repo.one()
  end

  def get_response_by_question(question_id, begin_at, end_at) do
    get_response_by_question(
      question_id,
      Date.from_iso8601!(begin_at),
      Date.from_iso8601!(end_at)
    )
  end

  @doc """
  Lists all question responses for a given question, ordered by period_start descending.
  """
  def list_responses_by_question(question_id) do
    QuestionResponse
    |> where([qr], qr.question_id == ^question_id)
    |> order_by([qr], desc: qr.period_start)
    |> Repo.all()
  end

  @doc """
  Gets a question response for a specific question and period.
  Returns nil if not found.
  """
  def get_response_by_period(question_id, %Date{} = period_start, %Date{} = period_end) do
    QuestionResponse
    |> where(
      [qr],
      qr.question_id == ^question_id and
        qr.period_start == ^period_start and
        qr.period_end == ^period_end
    )
    |> Repo.one()
  end

  @doc """
  Counts conversations in a project within a date range.
  """
  def count_conversations_in_period(%Scope{} = s, %Date{} = start_date, %Date{} = end_date) do
    start_datetime = NaiveDateTime.new!(start_date, ~T[00:00:00])
    end_datetime = NaiveDateTime.new!(end_date, ~T[23:59:59])

    from(c in Roda.Conversations.Conversation,
      where:
        c.project_id == ^s.project.id and
          c.inserted_at >= ^start_datetime and
          c.inserted_at <= ^end_datetime,
      select: count(c.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets all unique themes from completed question responses for a given question.
  Returns a list of theme maps with their hashed_name as unique identifier.
  """
  def get_all_themes(question_id) do
    question_id
    |> list_responses_by_question()
    |> Enum.filter(fn qr ->
      # Garder seulement les responses avec structured_response non vide
      qr.structured_response &&
        is_map(qr.structured_response) &&
        Map.has_key?(qr.structured_response, "themes")
    end)
    |> Enum.flat_map(fn qr ->
      qr.structured_response["themes"] || []
    end)
    |> Enum.uniq_by(fn theme -> theme["hashed_name"] end)
  end
end
