defmodule Roda.Projects do
  def add(args \\ %{}) do
    Roda.Organizations.add_project(args)
  end

  def get_conversations(project_id) do
    Roda.Organizations.get_conversations(project_id)
  end
end
