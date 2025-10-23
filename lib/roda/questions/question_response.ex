defmodule Roda.Questions.QuestionResponse do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Questions.{Question}

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "question_responses" do
    field :response_text, :string
    field :period_start, :date
    field :period_end, :date
    field :conversations_analyzed_count, :integer, default: 0

    belongs_to :question, Question, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :response_text,
      :period_start,
      :period_end,
      :conversations_analyzed_count,
      :question_id
    ])
    |> validate_required([:response_text, :period_start, :period_end, :question_id])
    # |> unique_constraint([:question_id, :analyse_id, :period_start])
    |> foreign_key_constraint(:question_id)
  end
end
