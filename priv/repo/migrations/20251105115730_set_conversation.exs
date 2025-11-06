defmodule Roda.Repo.Migrations.SetConversation do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :active, :boolean, default: true
    end
  end
end
