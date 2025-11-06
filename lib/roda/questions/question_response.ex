defmodule Roda.Questions.QuestionResponse do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Questions.Question

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  schema "question_responses" do
    field :narrative_response, :string
    field :structured_response, :map, default: %{}
    field :ids, {:array, :binary_id}, default: []
    field :complete, :boolean, default: false
    field :period_start, :date
    field :period_end, :date

    belongs_to :question, Question, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = response, attrs) do
    response
    |> cast(attrs, [
      :period_start,
      :period_end,
      :question_id,
      :narrative_response,
      :structured_response,
      :ids,
      :complete
    ])
    |> validate_required([:period_start, :period_end, :question_id])
    |> foreign_key_constraint(:question_id)
  end
end
