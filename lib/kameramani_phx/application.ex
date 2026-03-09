defmodule KameramaniPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        KameramaniPhxWeb.Telemetry,
        {Registry, keys: :unique, name: KameramaniPhx.ThumbnailRegistry},
        {DynamicSupervisor, name: KameramaniPhx.ThumbnailSupervisor},
        KameramaniPhx.Repo,
        KameramaniPhx.StreamManager,
        {DNSCluster, query: Application.get_env(:kameramani_phx, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: KameramaniPhx.PubSub},
        KameramaniPhxWeb.Presence,
        KameramaniPhxWeb.Endpoint
      ]
      |> maybe_add_rtmp_listener()

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

  defp maybe_add_rtmp_listener(children) do
    if Application.get_env(:kameramani_phx, :start_rtmp_listener, true) do
      List.insert_at(children, -2, KameramaniPhx.RTMPIngestListener)
    else
      children
    end
  end
end
