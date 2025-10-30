defmodule Roda.LLM do
  @behaviour Roda.Llm.LlmBehaviour
  alias Roda.LLM.Provider
  require Logger

  def models(%Provider{} = provider) do
    "#{provider.api_base_url}/v1/models"
    |> Req.get(
      headers: headers(provider),
      receive_timeout: 60_000
    )
    |> case do
      {:ok, %{status: 200, body: body}} -> {:ok, body["data"]}
      {:ok, %{status: 429}} -> {:error, :capacity_exceeded}
      {:ok, %{status: 401}} -> {:error, :bad_api_key}
      {:ok, %{body: %{"detail" => detail}}} -> {:error, detail}
      {:ok, _} -> {:error, :unknown}
      {:error, _} -> {:error, :bad_url}
    end
  end

  def chat_completion2(%Provider{provider_type: "openai"} = provider, content) do
    Logger.debug("Begin")

    response =
      provider
      |> get_chat_url()
      |> Req.post(
        headers: headers(provider),
        receive_timeout: 600_000,
        json: %{model: provider.model, messages: [%{role: "user", content: content}]}
      )

    Logger.debug("Request done #{inspect(response)}")

    with {:ok, %{body: body}} <- response,
         %{"choices" => [%{"message" => %{"content" => content}}]} <- body do
      {:ok, content}
    else
      {:ok, %{body: body}} -> {:api_error, body}
      error -> {:error, error}
    end
  end

  def chat_completion2(%Provider{provider_type: "anthropic"} = provider, content) do
    Logger.debug("Begin")

    response =
      provider
      |> get_chat_url()
      |> Req.post(
        headers: headers(provider),
        receive_timeout: 600_000,
        json: %{
          model: provider.model,
          max_tokens: 64000,
          messages: [%{role: "user", content: content}]
        }
      )

    Logger.debug("Request done #{inspect(response)}")

    with {:ok, %{body: body}} <- response,
         %{"content" => [%{"text" => text}]} <- body do
      {:ok, text}
    else
      {:ok, %{body: body}} -> {:api_error, body}
      error -> {:error, error}
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
        audio_binary
      ) do
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
      |> Multipart.add_part(Multipart.Part.text_field(provider.model, :model))

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

  defp headers(%{provider_type: "openai"} = provider) do
    [{"authorization", "Bearer #{provider.api_key}"}]
  end

  defp headers(%{provider_type: "anthropic"} = provider) do
    [{"x-api-key", "#{provider.api_key}"}, {"anthropic-version", "2023-06-01"}]
  end

  def get_embeddings_url(%{provider_type: "openai"} = provider) do
    "#{provider.api_base_url}/v1/embeddings"
  end

  def get_chat_url(%{provider_type: "openai"} = provider) do
    "#{provider.api_base_url}/v1/chat/completions"
  end

  def get_chat_url(%{provider_type: "anthropic"} = provider) do
    "#{provider.api_base_url}/v1/messages"
  end

  def get_chat_url(_p) do
    raise "nop"
  end
end
