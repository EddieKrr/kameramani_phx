defmodule KameramaniPhx.RTMPIngestListener do
  use Supervisor
  require Logger

  alias Membrane.RTMP.SourceBin
  # No need to require it if we are using SourceBin.child_spec
  # require Membrane.RTMP.SourceBin

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Starting RTMP Ingest Listener (Supervisor)...")

    children = [
      %{
        id: :rtmp_ingest_source_bin,
        start:
          {SourceBin, :start_link,
           [
             [
               url: "rtmp://127.0.0.1:1935/live",
               client_handler: KameramaniPhx.RTMPIngestListener.ClientHandler
             ]
           ]},
        type: :worker,
        restart: :permanent,
        shutdown: 5000
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
