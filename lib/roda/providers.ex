defmodule Roda.Providers do
  import Ecto.Query
  alias Roda.Organizations.Organization
  alias Roda.LLM.Provider
  alias Roda.Repo

  def get_provider_by_organization(organization, provider_type \\ "chat")

  def get_provider_by_organization(%Organization{} = organization, provider_type) do
    get_provider_by_organization(organization.id, provider_type)
  end

  def get_provider_by_organization(organization_id, provider_type)
      when is_binary(organization_id) do
    Provider
    |> where(
      [p],
      p.organization_id == ^organization_id and p.is_active == true and p.type == ^provider_type
    )
    |> Repo.one()
  end
end
