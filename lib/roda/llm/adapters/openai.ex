defmodule Roda.LLM.Adapters.Openai do
  alias Roda.LLM.Provider

  def headers(%Provider{} = p) do
    [
      {"authorization", "Bearer #{p.api_key}"}
    ]
  end

  def default_config() do
    %{
      api_base_url: "https://api.openai.com",
      id: "openai",
      module: __MODULE__
    }
  end

  def models(%Provider{} = p) do
    "#{p.api_base_url}/v1/models"
  end

  def chat_url(%Provider{} = p) do
    "#{p.api_base_url}/v1/chat/completions"
  end

  def build_stream_body(%Provider{model: model}, messages) do
    %{
      model: model,
      messages: messages,
      stream: true
    }
  end

  def parse_response_for_mode(:model, %{"data" => data}) do
    data
  end

  def parse_response_for_mode(:tools, %{
        "choices" => [
          %{"message" => %{"tool_calls" => [%{"function" => %{"arguments" => args}}]}}
        ]
      }),
      do: Jason.decode(args)

  def parse_response_for_mode(action, %{"choices" => [%{"message" => %{"content" => content}}]})
      when action in [:md_json, :json, :json_schema] do
    Jason.decode(content)
  end

  def parse_response_for_mode(:raw, %{"choices" => [%{"message" => %{"content" => content}}]}) do
    {:ok, content}
  end

  def parse_response_for_mode(_mode, _response) do
    {:error, :not_supported}
  end

  def parse_stream_chunk_for_mode(action, %{"choices" => [%{"delta" => %{"content" => chunk}}]})
      when action in [:md_json, :json, :json_schema, :raw] do
    chunk
  end

  def parse_stream_chunk_for_mode(:tools, %{
        "choices" => [
          %{"delta" => %{"tool_calls" => [%{"function" => %{"arguments" => chunk}}]}}
        ]
      }),
      do: chunk

  def parse_stream_chunk_for_mode(:tools, %{
        "choices" => [
          %{"delta" => delta}
        ]
      }) do
    case delta do
      nil -> ""
      %{} -> ""
      %{"content" => chunk} -> chunk
    end
  end

  def parse_stream_chunk_for_mode(_, %{"choices" => [%{"finish_reason" => "stop"}]}), do: ""
end
