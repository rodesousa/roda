defmodule Roda.OrganizationFixtures do
  alias Roda.{Repo, Accounts, Organizations}
  alias Roda.Accounts.Scope
  alias Roda.Organizations.{OrganizationMembership}

  def init_organization(args \\ []) do
    email = Keyword.get(args, :email, "admin@cohortes.co")
    role = Keyword.get(args, :role, "admin")

    orga =
      Organizations.add_organization!(%{
        name: "Orga test",
        embedding_dimension: 1024,
        embedding_provider_type: "openai",
        embedding_api_base_url: "https://api.mistral.ai",
        embedding_model: "mistral-embed",
        embedding_encrypted_api_key: "WaI5foGtA6c8EizOmT4LsZhgfG50ZhEq"
      })

    {:ok, user} =
      Accounts.register_user(%{
        email: email
      })

    {:ok, _} = Accounts.update_user_password(user, %{password: "Password123456"})

    {:ok, membership} =
      %OrganizationMembership{}
      |> OrganizationMembership.changeset(%{
        organization_id: orga.id,
        user_id: user.id,
        role: role
      })
      |> Repo.insert()

    scope = Scope.for_user_in_organization(user, orga, membership)
    {:ok, project} = Organizations.add_project(scope, %{"name" => "coucou"})
    scope = Scope.for_user_in_project(user, orga, membership, project)

    Roda.Accounts.PlatformAdmin.add_super_admin(scope.user.id)

    _audio =
      Organizations.add_provider(
        scope,
        %{
          provider_type: "openai",
          api_key: "WaI5foGtA6c8EizOmT4LsZhgfG50ZhEq",
          api_base_url: "https://api.mistral.ai",
          model: "voxtral-mini-2507",
          type: "audio"
        }
      )

    _chat =
      Organizations.add_provider(
        scope,
        %{
          provider_type: "mistral",
          api_key: "WaI5foGtA6c8EizOmT4LsZhgfG50ZhEq",
          api_base_url: "https://api.mistral.ai",
          model: "mistral-medium-2508",
          type: "chat"
        }
      )

    %{project: project, scope: scope}
  end
end
