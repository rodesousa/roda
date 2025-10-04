defmodule Roda.Services.Minio do
  @moduledoc """
  Provides functions to interact with MinIO/S3 storage.
  """

  alias ExAws, as: Minio

  @doc """
  Lists all objects in the specified bucket.

  ## Example

      iex> Minio.list("roda")
      {:ok, %{body: %{contents: [], name: "roda"}}}
  """
  def list(bucket) when is_bitstring(bucket) do
    bucket
    |> Minio.S3.list_objects()
    |> Minio.request!()
  end
end
