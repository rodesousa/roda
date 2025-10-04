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

  @doc """
  Uploads a file to the specified bucket and key.

  ## Example

      iex> Minio.upload_file("roda", "path/to/file.webm", file_binary)
      {:ok, "roda/path/to/file.webm"}
  """
  def upload_file(bucket, key, file_binary) when is_bitstring(bucket) and is_bitstring(key) do
    case Minio.S3.put_object(bucket, key, file_binary, acl: :private) |> Minio.request() do
      {:ok, _response} -> {:ok, "#{bucket}/#{key}"}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Uploads an audio chunk to MinIO storage.

  Generates a unique filename and stores in audio-chunks/ directory.

  ## Example

      iex> Minio.upload_audio_chunk(chunk_binary, "chunk.webm")
      {:ok, "roda/audio-chunks/550e8400-e29b-41d4-a716-446655440000.webm"}
  """
  def upload_audio_chunk(chunk_binary, original_filename) do
    chunk_id = Ecto.UUID.generate()
    extension = Path.extname(original_filename)
    key = "audio-chunks/#{chunk_id}#{extension}"

    upload_file(bucket(), key, chunk_binary)
  end

  defp bucket, do: "roda"
end
