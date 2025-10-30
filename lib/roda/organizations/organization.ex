defmodule Roda.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Uniq.UUID, autogenerate: true, version: 7}

  @derive {Inspect, except: [:embedding_api_base_url]}
  schema "organizations" do
    field :name, :string
    field :is_active, :boolean, default: true

    field :embedding_dimension, :integer
    field :embedding_provider_type, :string
    field :embedding_api_base_url, :string
    field :embedding_model, :string
    field :embedding_encrypted_api_key, Roda.Encrypted.Binary

    many_to_many :users, Roda.Accounts.User,
      join_through: Roda.Organizations.OrganizationMembership

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :name,
      :embedding_dimension,
      :embedding_provider_type,
      :embedding_api_base_url,
      :embedding_model,
      :embedding_encrypted_api_key
    ])
    |> validate_required([:name])
    |> validate_inclusion(:embedding_provider_type, ["openai", "anthopric"])
    |> validate_format(:embedding_api_base_url, ~r/^https:\/\//)
  end

  def name_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def update_embedding_changeset(%__MODULE__{} = organization, attrs) do
    organization
    |> cast(attrs, [
      :embedding_dimension,
      :embedding_provider_type,
      :embedding_api_base_url,
      :embedding_model
    ])
    |> validate_inclusion(:embedding_provider_type, ["openai", "anthopric"])
    |> validate_format(:embedding_api_base_url, ~r/^https:\/\//)
  end
end
