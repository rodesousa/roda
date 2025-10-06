defmodule Roda.Memgraph do
  @moduledoc """
  Memgraph graph database interface using Bolt.Sips.
  """

  @doc """
  Returns a connection from the Bolt.Sips pool.

  ## Example

      iex> Roda.Memgraph.conn()
      #PID<0.123.0>
  """
  def conn do
    Bolt.Sips.conn()
  end

  @doc """
  Executes a Cypher query and returns the result.

  ## Example

      iex> Roda.Memgraph.query("RETURN 1 AS num")
      {:ok, %Bolt.Sips.Response{results: [%{"num" => 1}]}}
  """
  def query(statement, params \\ %{}) do
    Bolt.Sips.query(conn(), statement, params)
  end

  @doc """
  Executes a Cypher query and returns the result or raises on error.

  ## Example

      iex> Roda.Memgraph.query!("CREATE (p:Person {name: $name}) RETURN p", %{name: "Alice"})
      %Bolt.Sips.Response{results: [%{"p" => ...}]}
  """
  def query!(statement, params \\ %{}) do
    Bolt.Sips.query!(conn(), statement, params)
  end

  @doc """
  Executes a query within a transaction.

  ## Example

      iex> Roda.Memgraph.transaction(fn ->
      ...>   Roda.Memgraph.query!("CREATE (p:Person {name: 'Bob'})")
      ...>   Roda.Memgraph.query!("CREATE (p:Person {name: 'Charlie'})")
      ...> end)
      {:ok, result}
  """
  def transaction(fun) do
    Bolt.Sips.transaction(conn(), fun)
  end
end
