defmodule Roda.OrganizationFixtures do
  alias Roda.Repo
  alias Roda.LLM.Provider
  alias Roda.Organization.{Organization, Project}

  def init_organization() do
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
    |> Repo.insert!()

    Provider.changeset(%{
      name: "mistral audio",
      provider_type: "openai",
      api_key: "Rakam",
      api_base_url: "https://api.mistral.ai",
      model: "voxtral-mini-2507",
      organization_id: org.id,
      type: "audio"
    })
    |> Repo.insert!()

    %{org: org, project: project}
  end
end
