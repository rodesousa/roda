defmodule Roda.LLM do
  alias Roda.LLM.{Provider}
  alias Roda.Minio
  require Logger

  def chat_completion(%Provider{} = provider, content) do
    response =
      provider
      |> get_chat_url()
      |> Req.post(
        headers: [{"authorization", "Bearer #{provider.api_key}"}],
        receive_timeout: 60_000,
        json: %{model: provider.model, messages: [%{role: "user", content: content}]}
      )

    with {:ok, %{body: body}} <- response,
         %{"choices" => [%{"message" => %{"content" => content}}]} <- body do
      content
    end
  end

  def embeddings(provider, content) when is_binary(content) do
    embeddings(provider, [content])
  end

  def embeddings(provider, content) when is_list(content) do
    response =
      provider
      |> get_embeddings_url()
      |> Req.post(
        headers: [{"authorization", "Bearer #{provider.api_key}"}],
        receive_timeout: 60_000,
        json: %{model: provider.model, input: content}
      )

    with {:ok, %{body: body}} <- response,
         %{"data" => content} <- body do
      content
    end
  end

  def audio_transcribe(
        %Provider{} = provider,
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

  def get_embeddings_url(%{provider_type: "openai"} = provider) do
    "#{provider.api_base_url}/v1/embeddings"
  end

  def get_chat_url(%Provider{provider_type: "openai"} = provider) do
    "#{provider.api_base_url}/v1/chat/completions"
  end

  def get_chat_url(%Provider{provider_type: "anthropic"} = provider) do
    "#{provider.api_base_url}/v1/messages"
  end

  def get_chat_url() do
    raise "nop"
  end
end
