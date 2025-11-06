defmodule Roda.Workers.Jobs do
  alias Roda.Repo
  import Ecto.Query

  @doc """
  Lists all Oban jobs for a specific question.

  ## Parameters
    - question_id: The ID of the question to filter jobs by

  ## Example

      iex> Roda.Workers.Jobs.list_question_jobs(123)
      [%Oban.Job{...}, ...]
  """
  def list_question_jobs(question_id) do
    Oban.Job
    |> where(
      [j],
      fragment("?->>'question_id' = ?", j.args, ^to_string(question_id)) and
        j.worker == "Roda.Workers.QuestionWorker"
    )
    |> Repo.all()
  end

  def delete_question_worker(question_id, period_start, period_end) do
    Oban.Job
    |> where(
      [j],
      fragment("?->>'question_id' = ?", j.args, ^to_string(question_id)) and
        fragment("?->>'period_start' = ?", j.args, ^to_string(period_start)) and
        fragment("?->>'period_end' = ?", j.args, ^to_string(period_end)) and
        j.worker == "Roda.Workers.QuestionWorker"
    )
    |> Repo.all()
    |> Enum.each(&Repo.delete!(&1))
  end
end
