defmodule Roda.Repo.Migrations.AddConversations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :is_active, :boolean, default: true
      add :embedding_dimension, :integer
      add :embedding_provider_type, :string
      add :embedding_model, :string
      add :embedding_api_base_url, :string
      add :embedding_encrypted_api_key, :binary
      timestamps(type: :utc_datetime)
    end

    create table(:projects, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :is_active, :boolean, default: true

      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create table(:conversations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :fully_transcribed, :boolean, default: false
      add :from_chat, :boolean, default: false

      add :project_id, references(:projects, type: :uuid, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create table(:chunks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :text, :text, null: false
      add :position, :integer, null: false
      add :path, :string

      add :conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create table(:llm_providers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :provider_type, :string, null: false
      add :api_key, :binary, null: false
      add :model, :string, null: false
      add :api_base_url, :string, null: false
      add :is_active, :boolean, default: true, null: false
      add :type, :string, null: false
      add :config, :map, default: %{}

      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:chunks, [:conversation_id])
    create index(:llm_providers, [:is_active])

    create unique_index(:llm_providers, [:organization_id, :type], where: "is_active = true")
  end
end
