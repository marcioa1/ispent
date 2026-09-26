defmodule Ispent.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      IspentWeb.Telemetry,
      Ispent.Repo,
      {DNSCluster, query: Application.get_env(:ispent, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ispent.PubSub},
      # Start a worker by calling: Ispent.Worker.start_link(arg)
      # {Ispent.Worker, arg},
      # Start to serve requests, typically the last entry
      IspentWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ispent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IspentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
