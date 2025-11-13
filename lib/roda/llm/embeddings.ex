defmodule Roda.Embeddings do
  @moduledoc """
  Not used yet
  """
  alias Roda.Conversations.Embedding.{Embedding1024, Embedding1536}
  alias Roda.Repo

  def add(%{embedding_dimension: 1024} = organization, embedding, chunk_id) do
    Embedding1024.changeset(%{
      model: organization.embedding_model,
      embedding: embedding,
      chunk_id: chunk_id
    })
    |> Repo.insert!()
  end

  def add(%{embedding_dimension: 1536} = organization, embedding, chunk_id) do
    Embedding1536.changeset(%{
      model: organization.embedding_model,
      embedding: embedding,
      chunk_id: chunk_id
    })
    |> Repo.insert!()
  end
end
