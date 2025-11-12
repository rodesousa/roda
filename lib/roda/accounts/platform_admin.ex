defmodule Roda.Accounts.PlatformAdmin do
  use Ecto.Schema
  import Ecto.Changeset
  alias Roda.Repo

  schema "platform_admins" do
    belongs_to :user, Roda.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end

  def add_super_admin(user_id) do
    changeset(%{user_id: user_id})
    |> Repo.insert!()
  end

  def get(user_id) do
    Repo.get(__MODULE__, user_id)
  end
end
