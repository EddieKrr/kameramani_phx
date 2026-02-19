defmodule KameramaniPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KameramaniPhxWeb.Telemetry,
      KameramaniPhx.Repo,
      KameramaniPhx.StreamManager,
      {DNSCluster, query: Application.get_env(:kameramani_phx, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: KameramaniPhx.PubSub},
      # RTMP Server for OBS ingest - listens on port 1935
      KameramaniPhx.OBSRTMPServer,
      # Note: KameramaniPhx.RTMPIngestListener is disabled because Membrane.RTMP.SourceBin
      # is a Bin component (not a GenServer) and cannot be started directly as a supervisor child.
      # RTMP streams are handled through Membrane Pipelines when clients connect.
      # KameramaniPhx.RTMPIngestListener,
      # Start a worker by calling: KameramaniPhx.Worker.start_link(arg)
      # {KameramaniPhx.Worker, arg},
      # Start to serve requests, typically the last entry
      KameramaniPhxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KameramaniPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KameramaniPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
