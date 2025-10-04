defmodule Roda.LLM.Template do
  @moduledoc """
  Predefined templates for common LLM providers.

  Provides default configuration values to help users quickly set up
  popular LLM providers without having to look up API endpoints and model names.

  ## Usage

      # Get template for OpenAI
      Template.get(:openai)
      #=> %{name: "OpenAI", provider_type: "openai", ...}

      # List all available templates
      Template.list()
      #=> [:openai, :anthropic, :gemini, :ollama]

      # Get available models for a provider
      Template.models(:openai)
      #=> ["gpt-4o", "gpt-4o-mini", ...]
  """

  @templates %{
    openai: %{
      name: "OpenAI",
      provider_type: "openai",
      api_base_url: "https://api.openai.com/v1",
      models: [],
      default_model: "gpt-4o",
      config: %{},
      capability: "chat"
    },
    openai_whisper: %{
      name: "OpenAI Whisper",
      provider_type: "openai",
      api_base_url: "https://api.openai.com/v1/audio/transcriptions",
      models: [],
      default_model: "whisper-1",
      config: %{},
      capability: "transcribe_audio"
    },
    mistral_whisper: %{
      name: "Mistral Whisper",
      provider_type: "mistral",
      api_base_url: "https://api.mistral.ai/v1/audio/transcriptions",
      models: [],
      default_model: "voxtral-mini-2507",
      config: %{},
      capability: "transcribe_audio"
    },
    anthropic: %{
      name: "Anthropic",
      provider_type: "anthropic",
      api_base_url: "https://api.anthropic.com",
      models: [],
      default_model: "claude-3-5-sonnet-20241022",
      config: %{},
      capability: "chat"
    },
    gemini: %{
      name: "Google Gemini",
      provider_type: "gemini",
      api_base_url: "https://generativelanguage.googleapis.com/v1beta",
      models: [],
      default_model: "gemini-1.5-pro",
      config: %{},
      capability: "chat"
    }
  }

  @doc """
  Returns the template for a specific provider.

  ## Examples

      iex> Template.get(:openai)
      %{name: "OpenAI", provider_type: "openai", ...}

      iex> Template.get(:unknown)
      nil
  """
  def get(provider_key) when is_atom(provider_key) do
    Map.get(@templates, provider_key)
  end

  @doc """
  Lists all available provider template keys.

  ## Examples

      iex> Template.list()
      [:openai, :anthropic, :gemini, :ollama]
  """
  def list do
    Map.keys(@templates)
  end

  @doc """
  Returns all templates as a map.

  ## Examples

      iex> Template.all()
      %{openai: %{...}, anthropic: %{...}, ...}
  """
  def all do
    @templates
  end

  @doc """
  Returns available models for a specific provider.

  ## Examples

      iex> Template.models(:openai)
      ["gpt-4o", "gpt-4o-mini", ...]

      iex> Template.models(:unknown)
      []
  """
  def models(provider_key) when is_atom(provider_key) do
    case get(provider_key) do
      nil -> []
      template -> template.models
    end
  end
end
