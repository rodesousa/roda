defmodule Roda.Organization.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string

    field :embedding_dimension, :integer
    field :embedding_provider_type, :string
    field :embedding_api_base_url, :string
    field :embedding_model, :string

    timestamps(type: :utc_datetime)
  end

  def name_changeset(%__MODULE__{} = project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def embedding_changeset(%__MODULE__{} = project, attrs) do
    project
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
