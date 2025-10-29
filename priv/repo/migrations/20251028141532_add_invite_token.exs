defmodule Roda.Repo.Migrations.AddInviteToken do
  use Ecto.Migration

  def change do
    create table(:invite_access_tokens) do
      add :token, :binary, null: false
      add :authenticated_at, :utc_datetime
      add :project_id, references(:projects, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:invite_access_tokens, [:token])
    create index(:invite_access_tokens, [:project_id])
  end
end
