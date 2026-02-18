defmodule KameramaniPhx.RTMPServer do
  use GenServer
  require Logger

  @port 1936

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting RTMP Server on port #{@port}")

    case :gen_tcp.listen(@port, [
           :binary,
           {:packet, 0},
           {:active, true},
           {:reuseaddr, true}
         ]) do
      {:ok, listen_socket} ->
        {:ok, %{listen_socket: listen_socket}, {:continue, :accept_connections}}

      {:error, reason} ->
        Logger.error("Failed to start RTMP server: #{reason}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept_connections, state) do
    spawn_link(fn -> accept_loop(state.listen_socket) end)
    {:noreply, state}
  end

  defp accept_loop(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        Logger.info("New RTMP connection from #{inspect(socket)}")
        spawn_link(fn -> handle_client(socket) end)
        accept_loop(listen_socket)

      {:error, reason} ->
        Logger.error("Error accepting connection: #{reason}")
    end
  end

  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, data} ->
        Logger.info("Received RTMP data: #{inspect(data)}")
        # Simple RTMP handshake response
        response = <<0x03, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
        :gen_tcp.send(socket, response)
        handle_client(socket)

      {:error, :closed} ->
        Logger.info("Client disconnected")

      {:error, reason} ->
        Logger.error("Error handling client: #{reason}")
    end
  end
end
