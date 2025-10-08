defmodule Roda.Repo.Migrations.AddProject do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :memgraph_chunk_capacity, :integer, null: false
      add :memgraph_entity_capacity, :integer, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
