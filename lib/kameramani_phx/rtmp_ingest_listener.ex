defmodule KameramaniPhx.RTMPIngestListener do
  use Supervisor
  require Logger

  def start_link(opts), do: Supervisor.start_link(__MODULE__, :ok, opts)

  @impl true
  def init(:ok) do
    Logger.info("🚀 Starting RTMP Server on port 1935")

    children = [
      %{
        id: :rtmp_server,
        start: {Membrane.RTMPServer, :start_link, [[
          port: 1935,
          handle_new_client: &KameramaniPhx.RTMPIngestListener.ClientHandler.handle_new_client/3
        ]]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
