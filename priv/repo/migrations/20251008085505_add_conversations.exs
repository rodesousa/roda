defmodule Roda.Repo.Migrations.AddConversations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :embedding_dimension, :integer, null: false
      add :embedding_provider_type, :string, null: false
      add :embedding_model, :string, null: false
      add :embedding_api_base_url, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create table(:projects, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false

      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create table(:conversations, primary_key: false) do
      add :id, :uuid, primary_key: true
      timestamps(type: :utc_datetime)
    end

    create table(:chunks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :text, :text
      add :position, :integer

      add :conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chunks, [:conversation_id])
  end
end
