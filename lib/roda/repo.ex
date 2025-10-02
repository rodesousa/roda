defmodule Roda.Repo do
  use Ecto.Repo,
    otp_app: :roda,
    adapter: Ecto.Adapters.Postgres
end
