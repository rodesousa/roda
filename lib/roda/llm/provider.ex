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
  - `:model` - Default model to use (e.g., "gpt-4o", "claude-3-5-sonnet")
  - `:is_active` - Whether this provider is currently active
  - `:config` - JSON map for provider-specific options (temperature, max_tokens, etc.)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Inspect, except: [:api_key]}
  schema "llm_providers" do
    field :name, :string
    field :provider_type, :string
    field :api_key, Roda.Encrypted.Binary
    field :api_base_url, :string
    field :model, :string
    field :is_active, :boolean, default: true
    field :config, :map, default: %{}

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required([:name, :provider_type, :api_key])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:api_key, min: 1)
  end

  def update_changeset(provider, attrs) do
    provider
    |> cast(attrs, [:api_key, :name, :model, :is_active, :config])
    |> validate_required([:api_key])
    |> validate_length(:api_key, min: 1)
  end
end
