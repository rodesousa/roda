defmodule Roda.Repo.Migrations.AddEmbeddingSchema do
  use Ecto.Migration

  def up do
    # Enable pgvector extension
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    create table(:embeddings_1024, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :chunk_id, references(:chunks, type: :uuid, on_delete: :delete_all), null: false
      add :model, :string, null: false
      add :embedding, :vector, size: 1024
      timestamps(type: :utc_datetime)
    end

    create index("embeddings_1024", ["embedding vector_cosine_ops"], using: :hnsw)

    create index(:embeddings_1024, [:chunk_id])

    create table(:embeddings_1536, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :chunk_id, references(:chunks, type: :uuid, on_delete: :delete_all), null: false
      add :model, :string, null: false
      add :dims, :integer, null: false
      add :embedding, :vector, size: 1536
      timestamps(type: :utc_datetime)
    end

    create index("embeddings_1536", ["embedding vector_cosine_ops"], using: :hnsw)
    create index(:embeddings_1536, [:chunk_id])
  end

  def down do
    drop table(:embeddings_1536)
    drop table(:embeddings_1024)
  end
end
