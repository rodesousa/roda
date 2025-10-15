defmodule Roda.Minio do
  @moduledoc """
  Provides functions to interact with MinIO/S3 storage.
  """

  alias ExAws, as: Minio

  @doc """
  Lists all objects in the specified bucket.

  ## Example

      iex> Minio.list("roda")
      {:ok, %{body: %{contents: [], name: "roda"}}}

      iex> Minio.list("roda", pref: "org")
      {:ok, %{body: %{contents: [], name: "roda"}}}
  """
  def list(args \\ []) do
    bucket()
    |> Minio.S3.list_objects(args)
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

      iex> Minio.upload_audio_chunk(chunk_binary, "folder/folder", chunk.webm")
      {:ok, "roda/audio-chunks/550e8400-e29b-41d4-a716-446655440000.webm"}
  """
  def upload_audio_chunk(chunk_binary, path, original_filename) do
    chunk_id = Uniq.UUID.uuid7()
    extension = Path.extname(original_filename)
    key = "#{path}/#{chunk_id}#{extension}"

    upload_file(bucket(), key, chunk_binary)
  end

  @doc """
  Downloads an file chunk from MinIO storage.

  ## Example

      iex> Minio.get_file("roda/audio-chunks/uuid.webm")
      {:ok, <<binary_data>>}

      iex> Minio.get_file("audio-chunks/uuid.webm")
      {:ok, <<binary_data>>}
  """
  def get_file(key) when is_bitstring(key) do
    Minio.S3.get_object(bucket(), key)
    |> Minio.request()
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  defp bucket, do: "roda"
end
