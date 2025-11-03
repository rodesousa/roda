defmodule Roda.LLM.Adapters.Anthropic do
  alias Roda.LLM.Provider

  def default_config(),
    do: %{
      api_base_url: "https://api.anthropic.com/",
      id: "anthropic",
      module: __MODULE__
    }

  def headers(%Provider{} = p) do
    [
      {"x-api-key", "#{p.api_key}"},
      {"anthropic-version", "2023-06-01"}
    ]
  end

  def models(%Provider{} = p) do
    "#{p.api_base_url}/v1/models"
  end

  def chat_url(%Provider{} = p) do
    "#{p.api_base_url}/v1/messages"
  end

  defp build_stream_body(%Provider{model: model}, messages) do
    %{
      model: model,
      messages: messages,
      stream: true,
      max_tokens: 64000
    }
  end

  def parse_response_for_mode(:model, data) do
    data
  end

  def parse_response_for_mode(:model, %{"data" => data}) do
    Jason.encode!(data)
  end

  def parse_response_for_mode(:raw, %{"content" => [%{"text" => text}]}) do
    {:ok, text}
  end

  def parse_stream_chunk_for_mode(mode, %{"type" => event})
      when mode in [:tools, :raw] and
             event in [
               "message_start",
               "ping",
               "content_block_start",
               "content_block_stop",
               "message_stop",
               "message_delta",
               "completion"
             ] do
    ""
  end

  def parse_stream_chunk_for_mode(:raw, %{
        "type" => "content_block_delta",
        "delta" => %{"text" => text, "type" => "text_delta"}
      }) do
    text
  end

  def parse_stream_chunk_for_mode(:tools, %{
        "type" => "content_block_delta",
        "delta" => %{"partial_json" => delta, "type" => "input_json_delta"}
      }) do
    delta
  end

  def parse_response_for_mode(:tools, %{"content" => [%{"input" => args, "type" => "tool_use"}]}) do
    args
  end
end
