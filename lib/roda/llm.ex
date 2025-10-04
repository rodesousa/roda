defmodule Roda.Llm do
  alias Roda.LLM.{Provider, Audio}
  alias Roda.Minio

  def chat_completion() do
  end

  def audio_transcribe(
        %Provider{capability: "transcribe_audio"} = provider,
        bucket,
        chunk_filepath
      ) do
    {:ok, audio_binary} = Minio.get_file(bucket, chunk_filepath)

    file_part = %Multipart.Part{
      body: audio_binary,
      headers: [
        {"content-disposition", "form-data; name=\"file\"; filename=\"audio.webm\""},
        {"content-type", "audio/webm"}
      ]
    }

    multipart =
      Multipart.new()
      |> Multipart.add_part(file_part)
      |> Multipart.add_part(Multipart.Part.text_field(provider.default_model, :model))

    headers =
      [
        {"authorization", "Bearer #{provider.api_key}"},
        {"content-type", Multipart.content_type(multipart, "multipart/form-data")}
      ]

    case Req.post(provider.api_base_url,
           headers: headers,
           body: Multipart.body_stream(multipart)
         ) do
      {:ok, %{status: 200, body: %{"text" => text}}} ->
        {:ok, text}

      {:ok, %{status: status, body: body}} ->
        {:error, "API error #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
