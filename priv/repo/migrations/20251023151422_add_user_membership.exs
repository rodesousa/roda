defmodule Roda.Repo.Migrations.AddUserMembership do
  use Ecto.Migration

  def change do
    create table(:organization_memberships, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false

      add :role, :string, null: false

      timestamps(type: :utc_datetime)
    end

    # create unique_index(:organization_memberships, [:user_id, :organization_id])
    # create index(:organization_memberships, [:organization_id])
    # create index(:organization_memberships, [:user_id])

    create table(:platform_admins) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end
  end
end
