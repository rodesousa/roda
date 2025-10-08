defmodule Roda.Projects do
  alias Roda.Repo
  alias Roda.Project.Project

  def add(args \\ %{}) do
    Project.changeset(args)
    |> Repo.insert()
  end

end
