defmodule Roda.Repo.Migrations.CreatePromptConversations do
  use Ecto.Migration

  def change do
    create table(:prompt_conversations, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :title, :string, null: false

      add :begin_at, :naive_datetime
      add :end_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create table(:prompt_messages, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :conversation_id,
          references(:prompt_conversations, type: :binary_id, on_delete: :delete_all),
          null: false

      add :role, :string, null: false
      add :content, :text, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:prompt_conversations, [:project_id])
    create index(:prompt_messages, [:conversation_id])
  end
end
