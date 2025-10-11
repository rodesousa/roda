defmodule Roda.Repo.Migrations.AddLlm do
  use Ecto.Migration

  def change do
    create table(:llm_providers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :provider_type, :string, null: false
      add :api_key, :binary, null: false
      add :model, :string
      add :is_active, :boolean, default: true, null: false
      add :config, :map, default: %{}

      timestamps()
    end

    create unique_index(:llm_providers, [:provider_type, :name])
    create index(:llm_providers, [:is_active])
  end
end
