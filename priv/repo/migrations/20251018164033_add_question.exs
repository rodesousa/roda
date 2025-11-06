defmodule Roda.Repo.Migrations.AddQuestion do
  use Ecto.Migration

  def change do
    create table(:questions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :prompt, :text, null: false

      add :project_id, references(:projects, type: :uuid, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create table(:question_responses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :narrative_response, :text
      add :structured_response, :map
      add :ids, {:array, :uuid}, default: []
      add :complete, :boolean

      add :period_start, :date, null: false
      add :period_end, :date, null: false

      add :question_id, references(:questions, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
