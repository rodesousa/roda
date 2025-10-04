defmodule Roda.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RodaWeb.Telemetry,
      Roda.Repo,
      {DNSCluster, query: Application.get_env(:roda, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:roda, Oban)},
      {Phoenix.PubSub, name: Roda.PubSub},
      # Start a worker by calling: Roda.Worker.start_link(arg)
      # {Roda.Worker, arg},
      # Start to serve requests, typically the last entry
      RodaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Roda.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RodaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
