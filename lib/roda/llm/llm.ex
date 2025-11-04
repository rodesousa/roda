defmodule Roda.LLM do
  @behaviour Roda.Llm.LlmBehaviour
  alias Roda.LLM.Provider
  require Logger

  def models(%Provider{} = provider) do
    adapter =
      get_adapter(provider)

    response =
      adapter.module.models(provider)
      |> Req.get(
        headers: adapter.module.headers(provider),
        receive_timeout: 60_000
      )

    with {:ok, %{status: 200, body: body}} <- response,
         content <- adapter.module.parse_response_for_mode(:model, body) do
      content
    else
      {:ok, %{status: 429}} ->
        {:error, :capacity_exceeded}

      {:ok, %{status: 401}} ->
        {:error, :bad_api_key}

      {:ok, %{status: status}} ->
        {:error, status}

      _ ->
        {:error, :bad_url}
    end
  end

  def chat_completion(%Provider{} = provider, message) do
    adapter = get_adapter(provider)

    Logger.debug("Begin")

    response =
      adapter.module.chat_url(provider)
      |> Req.post(
        headers: adapter.module.headers(provider),
        receive_timeout: 600_000,
        json: %{model: provider.model, max_tokens: 64000, messages: message}
      )

    Logger.debug("Request done #{inspect(response)}")

    with {:ok, %{body: body}} <- response do
      adapter.module.parse_response_for_mode(:raw, body)
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

  @doc """
  Streams chat completion responses.

  Returns a Stream that emits chunks as they arrive from the LLM provider.

  ## Parameters
    - `provider`: The Provider struct with API credentials
    - `messages`: List of messages in format [%{role: "user", content: "..."}]

  ## Stream emits
    - `{:chunk, text}` - A chunk of the response
    - `{:done}` - Stream completed successfully
    - `{:error, reason}` - An error occurred

  ## Example

      iex> provider |> Roda.LLM.chat_completion_stream(messages) |> Enum.each(fn
      ...>   {:chunk, text} -> IO.write(text)
      ...>   {:done} -> IO.puts("Done!")
      ...>   {:error, reason} -> IO.puts("Error: reason")
      ...> end)
  """
  def chat_completion_stream(%Provider{} = provider, messages) do
    adapter = get_adapter(provider)
    url = adapter.module.chat_url(provider)
    body = adapter.module.build_stream_body(provider, messages)

    pid = self()
    ref = make_ref()

    Stream.resource(
      # Start function: lance la requête HTTP streaming
      fn ->
        Task.async(fn ->
          try do
            url
            |> Req.post(
              headers: adapter.module.headers(provider),
              json: body,
              receive_timeout: 600_000,
              into: fn
                {:data, data}, {req, resp} ->
                  send(pid, {ref, :data, data})
                  {:cont, {req, resp}}

                other, acc ->
                  send(pid, {ref, :other, other})
                  {:cont, acc}
              end
            )

            send(pid, {ref, :done})
          rescue
            e ->
              Logger.error("Stream error: #{inspect(e)}")
              send(pid, {ref, :error, Exception.message(e)})
          end
        end)
      end,
      # Next function: reçoit et parse les chunks SSE
      fn task ->
        receive do
          {^ref, :data, data} ->
            chunks = parse_and_extract_chunks(data, adapter)
            {chunks, task}

          {^ref, :done} ->
            {:halt, task}

          {^ref, :error, reason} ->
            {[{:error, reason}], task}

          {^ref, :other, _} ->
            {[], task}
        after
          100 ->
            if Process.alive?(task.pid) do
              {[], task}
            else
              {:halt, task}
            end
        end
      end,
      # After function: cleanup
      fn _task -> nil end
    )
    |> Stream.concat([{:done}])
  end

  defp build_stream_body(%Provider{provider_type: "openai", model: model}, messages) do
    %{
      model: model,
      messages: messages,
      stream: true
    }
  end

  defp build_stream_body(%Provider{provider_type: "anthropic", model: model}, messages) do
    %{
      model: model,
      messages: messages,
      stream: true,
      max_tokens: 64000
    }
  end

  defp parse_and_extract_chunks(data, adapter) do
    data
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "data: "))
    |> Enum.map(&String.replace_prefix(&1, "data: ", ""))
    |> Enum.reject(&(&1 == "[DONE]"))
    |> Enum.flat_map(fn json_str ->
      case Jason.decode(json_str) do
        {:ok, parsed} ->
          case adapter.module.parse_stream_chunk_for_mode(:raw, parsed) do
            chunk when is_binary(chunk) and chunk != "" -> [{:chunk, chunk}]
            _ -> []
          end

        {:error, _} ->
          []
      end
    end)
  end

  def get_adapter(provider) do
    list_adapter()
    |> Enum.find(&(Map.get(&1, :id) == provider.provider_type))
  end

  def list_adapter() do
    adapters()
    |> Enum.map(fn module ->
      module.default_config()
    end)
  end

  defp adapters() do
    :application.get_key(:roda, :modules)
    |> then(fn
      {:ok, all_modules} -> all_modules
      _ -> []
    end)
    |> Enum.filter(fn module ->
      String.starts_with?("#{module}", "Elixir.Roda.LLM.Adapters")
    end)
  end
end
