defmodule Roda.Workers.EmbeddingWorker do
  alias Roda.{LLM, Repo, Embeddings}
  alias Roda.Organization.Organization
  require Logger

  use Oban.Worker,
    max_attempts: 3,
    queue: :embedding

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"chunks" => chunks, "organization_id" => organization_id}}) do
    organization = Repo.get(Organization, organization_id)

    chunk_ids =
      Enum.map(chunks, & &1["text"])

    LLM.embeddings(
      %{
        provider_type: organization.embedding_provider_type,
        api_base_url: organization.embedding_api_base_url,
        api_key: organization.embedding_encrypted_api_key,
        model: organization.embedding_model
      },
      chunk_ids
    )
    |> Enum.zip(chunks)
    |> Enum.each(fn {embed, chunk} ->
      Embeddings.add(organization, embed["embedding"], chunk["id"])
    end)

    :ok
  end
end
