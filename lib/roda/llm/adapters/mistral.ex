defmodule Roda.LLM.Adapters.Mistral do
  alias Roda.LLM.Adapters.Openai

  def default_config() do
    %{
      api_base_url: "https://api.mistral.ai",
      id: "mistral",
      module: __MODULE__
    }
  end

  defdelegate headers(p), to: Openai

  defdelegate parse_response_for_mode(action, body), to: Openai

  defdelegate parse_stream_chunk_for_mode(action, body), to: Openai

  defdelegate models(provider), to: Openai

  defdelegate chat_url(provider), to: Openai

  defdelegate build_stream_body(provider, messages), to: Openai
end
