defmodule Roda.LLM.Provider do
  @moduledoc """
  Schema for LLM provider configuration.

  A provider represents a configured LLM service (OpenAI, Anthropic, Google, etc.)
  with encrypted API credentials stored in the database.

  ## Fields

  - `:provider_type` - Provider identifier ("openai", "anthropic", "gemini")
  - `:api_key` - Encrypted API key (uses Cloak.Ecto for AES-256-GCM encryption)
  - `:api_base_url` - Custom endpoint URL (optional, for proxies or self-hosted)
  - `:model` - Default model to use (e.g., "gpt-4o", "claude-3-5-sonnet")
  - `:is_active` - Whether this provider is currently active
  - `:config` - JSON map for provider-specific options (temperature, max_tokens, etc.)
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Organizations.Organization

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}
  @derive {Inspect, except: [:api_key]}
  schema "llm_providers" do
    field :provider_type, :string
    field :api_key, Roda.Encrypted.Binary
    field :api_base_url, :string
    field :model, :string
    field :is_active, :boolean, default: true
    field :type, :string
    field :config, :map, default: %{}

    belongs_to :organization, Organization, type: :binary_id
    timestamps()
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%__MODULE__{} = provider, attrs) do
    provider
    |> cast(attrs, __schema__(:fields))
    |> validate_required(required())
    |> validate_inclusion(:type, ["chat", "audio"])
  end

  defp required(),
    do: [:provider_type, :api_key, :model, :organization_id, :api_base_url, :type]
end
