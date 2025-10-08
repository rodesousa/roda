defmodule Roda.Repo.Migrations.AddConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      timestamps(type: :utc_datetime)
    end

    create table(:chunks) do
      add :text, :text
      add :position, :integer
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chunks, [:conversation_id])
  end
end
