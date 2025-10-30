defmodule RodaWeb.ChunkController do
  use RodaWeb, :controller

  alias Roda.{Minio, Conversations}

  @doc """
  Uploads an audio chunk to MinIO storage.

  Receives multipart/form-data with:
  - chunk: audio file
  - timestamp: ISO datetime string
  """
  def upload(conn, %{
        "chunk" => chunk_upload,
        "conversation_id" => conversation_id,
        "timestamp" => timestamp
      }) do
    {:ok, path} = Conversations.get_conversation_minio_path(conversation_id)

    project =
      with {:ok, file_binary} <- File.read(chunk_upload.path),
           {:ok, path} <- Minio.upload_audio_chunk(file_binary, path, chunk_upload.filename) do
        json(conn, %{
          success: true,
          path: path,
          timestamp: timestamp,
          filename: chunk_upload.filename
        })
      else
        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{success: false, error: inspect(reason)})
      end
  end

  def upload(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{success: false, error: "Missing chunk or timestamp"})
  end
end
