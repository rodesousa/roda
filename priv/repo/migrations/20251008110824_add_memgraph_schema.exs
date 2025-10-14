defmodule Roda.Repo.Migrations.AddMemgraphSchema do
  use Ecto.Migration
  alias Roda.Memgraph

  def change do
    # Setup Memgraph schema (constraints + indexes)
    # Cette migration s'exécute UNE FOIS pour initialiser Memgraph

    # Start Bolt.Sips manually (not started during migrations)
    {:ok, _} =
      Bolt.Sips.start_link(
        url: "bolt://localhost:7687",
        basic_auth: [username: "memgraph", password: "memgraph"],
        pool_size: 5
      )

    # Constraints
    execute_memgraph("CREATE CONSTRAINT ON (c:Chunk) ASSERT c.id IS UNIQUE;")
    execute_memgraph("CREATE CONSTRAINT ON (c:Chunk) ASSERT EXISTS (c.project_id);")

    execute_memgraph("CREATE CONSTRAINT ON (e:Entity) ASSERT e.id IS UNIQUE;")
    execute_memgraph("CREATE CONSTRAINT ON (e:Entity) ASSERT EXISTS (e.project_id);")
    execute_memgraph("CREATE CONSTRAINT ON (e:Entity) ASSERT EXISTS (e.organization_id);")

    # Property indexes
    execute_memgraph("CREATE INDEX ON :Chunk(id);")
    execute_memgraph("CREATE INDEX ON :Chunk(project_id);")

    execute_memgraph("CREATE INDEX ON :Entity(project_id);")
    execute_memgraph("CREATE INDEX ON :Entity(organization_id);")
    execute_memgraph("CREATE INDEX ON :Entity(type);")
    execute_memgraph("CREATE INDEX ON :Entity(entity_dedup_hash);")
    execute_memgraph("CREATE INDEX ON :Entity(entity_normalized_name);")
  end

  defp execute_memgraph(query) do
    case Memgraph.query(query) do
      {:ok, _} ->
        :ok

      {:error, %{code: "Neo.ClientError.Schema.ConstraintAlreadyExists"}} ->
        :ok

      {:error, %{code: "Neo.ClientError.Schema.IndexAlreadyExists"}} ->
        :ok

      {:error, reason} ->
        raise "Memgraph query failed: #{inspect(reason)}"
    end
  end
end
