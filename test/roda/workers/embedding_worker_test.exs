defmodule Roda.Workers.EmbeddingWorkerTest do
  use Roda.DataCase

  alias Roda.Repo
  alias Roda.LLM.Provider
  alias Roda.Conversations.{Conversation, Chunk}
  alias Roda.Organization.{Organization, Project}

  setup do
    org =
      %Organization{name: "Test Org", embedding_dimension: 1024, embedding_model: "test"}
      |> Repo.insert!()

    project =
      %Project{name: "Test Project", organization_id: org.id}
      |> Repo.insert!()

    Provider.changeset(%{
      name: "mistral medium",
      provider_type: "openai",
      api_key: "Ambroise",
      api_base_url: "https://api.mistral.ai",
      model: "mistral-medium-2508",
      organization_id: org.id,
      type: "chat"
    })
    |> Repo.insert()

    Provider.changeset(%{
      name: "mistral audio",
      provider_type: "openai",
      api_key: "Rakam",
      api_base_url: "https://api.mistral.ai",
      model: "voxtral-mini-2507",
      organization_id: org.id,
      type: "audio"
    })
    |> Repo.insert()

    %{organization: org, project: project}
  end

  test "coucou", %{organization: org, project: project} do
    {:ok, %{conversation: conversation}} =
      %Ecto.Multi{}
      |> Ecto.Multi.insert(:conversation, fn _ ->
        Conversation.changeset(%{project_id: project.id})
      end)
      |> Ecto.Multi.insert(:chunk, fn %{conversation: %{id: id}} ->
        Chunk.changeset(%{
          text: "osef",
          position: 0,
          conversation_id: id
        })
      end)
      |> Repo.transaction()

    # dirty ... dancing
    # import Oban.Testing
    # assert_enqueued(
    #   worker: Roda.Workers.EmbeddingWorker,
    #   args: %{conversation_id: conversation.id, organization_id: org.id}
    # )
    assert Roda.Workers.EmbeddingWorker.perform(%Oban.Job{
             args: %{"conversation_id" => conversation.id, "organization_id" => org.id}
           }) == :ok
  end
end
