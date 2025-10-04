defmodule Roda.LLM.Provider do
  @moduledoc """
  Schema for LLM provider configuration.

  A provider represents a configured LLM service (OpenAI, Anthropic, Google, etc.)
  with encrypted API credentials stored in the database.

  ## Fields

  - `:name` - User-friendly name (e.g., "Production OpenAI")
  - `:provider_type` - Provider identifier ("openai", "anthropic", "gemini")
  - `:api_key` - Encrypted API key (uses Cloak.Ecto for AES-256-GCM encryption)
  - `:api_base_url` - Custom endpoint URL (optional, for proxies or self-hosted)
  - `:default_model` - Default model to use (e.g., "gpt-4o", "claude-3-5-sonnet")
  - `:is_active` - Whether this provider is currently active
  - `:config` - JSON map for provider-specific options (temperature, max_tokens, etc.)
  - `:capability` - chat | transcribe_audio
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Inspect, except: [:api_key]}
  schema "llm_providers" do
    field :name, :string
    field :capability, :string, default: "chat"
    field :provider_type, :string
    field :api_key, Roda.Encrypted.Binary
    field :api_base_url, :string
    field :default_model, :string
    field :is_active, :boolean, default: true
    field :config, :map, default: %{}

    timestamps()
  end

  @doc """
  Changeset for creating a new provider.
  """
  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_inclusion(:capability, ["chat", "transcribe_audio"])
    |> validate_required([:name, :provider_type, :api_key, :capability])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:api_key, min: 1)
  end

  @doc """
  Changeset for updating a provider.
  Allows updating without re-entering the API key.
  """
  def update_changeset(provider, attrs) do
    provider
    |> cast(attrs, [:name, :api_base_url, :default_model, :is_active, :config])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
  end

  @doc """
  Changeset for updating API key only.
  """
  def update_api_key_changeset(provider, attrs) do
    provider
    |> cast(attrs, [:api_key])
    |> validate_required([:api_key])
    |> validate_length(:api_key, min: 1)
  end
end
