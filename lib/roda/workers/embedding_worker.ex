defmodule Roda.Workers.EmbeddingWorker do
  alias Roda.{LLM, Repo, Embeddings}
  alias Roda.Organization.Organization
  alias Roda.Conversations
  require Logger

  use Oban.Worker,
    max_attempts: 3,
    queue: :embedding

  defp llm() do
    Application.get_env(:roda, :llm)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"conversation_id" => conversation_id, "organization_id" => organization_id}
      }) do
    organization = Repo.get(Organization, organization_id)
    conversation = Conversations.get_conversation(conversation_id)
    text_chunks = Enum.map(conversation.chunks, & &1.text)

    llm().embeddings(
      %{
        provider_type: organization.embedding_provider_type,
        api_base_url: organization.embedding_api_base_url,
        api_key: organization.embedding_encrypted_api_key,
        model: organization.embedding_model
      },
      text_chunks
    )
    |> Enum.zip(conversation.chunks)
    |> Enum.each(fn {embed, chunk} ->
      Embeddings.add(organization, embed["embedding"], chunk.id)
    end)

    :ok
  end
end
