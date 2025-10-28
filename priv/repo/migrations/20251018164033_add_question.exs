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

      add :period_start, :date, null: false
      add :period_end, :date, null: false

      add :question_id, references(:questions, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:analyses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false

      add :project_id, references(:projects, type: :uuid, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create table(:question_analyses, primary_key: false) do
      add :question_id, references(:questions, type: :uuid, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :analyse_id, references(:analyses, type: :uuid, on_delete: :delete_all),
        null: false,
        primary_key: true

      timestamps(type: :utc_datetime)
    end

    create table(:question_analyse_responses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :response_text, :text, null: false

      add :period_start, :date, null: false
      add :period_end, :date, null: false
      add :conversations_analyzed_count, :integer, default: 0

      add :question_id, references(:questions, type: :uuid, on_delete: :delete_all), null: false
      add :analyse_id, references(:analyses, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:question_analyse_responses, [:question_id, :analyse_id, :period_start])
  end
end
