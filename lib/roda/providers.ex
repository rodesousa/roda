defmodule Roda.Providers do
  import Ecto.Query
  alias Roda.Organization.Organization
  alias Roda.LLM.Provider
  alias Roda.Repo

  def get_provider_by_organization_id(%Organization{} = organization) do
    get_provider_by_organization_id(organization.id)
  end

  def get_provider_by_organization_id(organization_id) when is_binary(organization_id) do
    Provider
    |> where([p], p.organization_id == ^organization_id and p.is_active == true)
    |> Repo.one()
  end
end
