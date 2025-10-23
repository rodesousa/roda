defmodule Roda.Organizations do
  import Ecto.Query
  alias Roda.Repo
  alias Roda.Organizations.{Project, Organization}
  alias Roda.Conversations.Conversation

  def add_organization!(args) do
    Organization.changeset(args)
    |> Repo.insert!()
  end

  def add_project(args \\ %{}) do
    Project.changeset(args)
    |> Repo.insert()
  end

  def list_project_by_orga_id(orga_id) do
    Project
    |> where([p], p.organization_id == ^orga_id and p.is_active == true)
    |> Repo.all()
  end

  def get_conversations(project_id) do
    Conversation
    |> where([c], c.project_id == ^project_id)
    |> preload([:chunks])
    |> Repo.all()
  end

  def list_orgas() do
    Organization
    |> where([o], o.is_active == true)
    |> Repo.all()
  end

  def get_orga_by_id(orga_id) do
    Organization
    |> where([o], o.id == ^orga_id and o.is_active == true)
    |> select([:name, :id])
    |> Repo.one()
  end

  def get_project_by_id(project_id) do
    Project
    |> where([o], o.id == ^project_id and o.is_active == true)
    |> select([:name, :id])
    |> Repo.one()
  end
end
