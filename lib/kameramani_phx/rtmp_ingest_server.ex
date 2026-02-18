defmodule KameramaniPhx.RTMPIngestServer do
  use GenServer
  require Logger

  alias KameramaniPhx.Streaming
  alias KameramaniPhxWeb.Streaming.Pipeline

  @port 1936

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting RTMP Ingest Server on port #{@port}")
    
    # Start a simple TCP listener for RTMP connections
    case :gen_tcp.listen(@port, [
      :binary,
      {:packet, 0},
      {:active, true},
      {:reuseaddr, true}
    ]) do
      {:ok, listen_socket} ->
        spawn_link(fn -> accept_loop(listen_socket) end)
        {:ok, %{listen_socket: listen_socket}}
      {:error, reason} ->
        Logger.error("Failed to start RTMP server: #{reason}")
        {:stop, reason}
    end
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
        Logger.info("Received RTMP data: #{byte_size(data)} bytes")
        
        # Try to extract stream key from RTMP handshake
        case extract_stream_key(data) do
          {:ok, stream_key} ->
            Logger.info("Stream key detected: #{stream_key}")
            handle_stream_key(socket, stream_key)
          {:error, :not_found} ->
            Logger.info("No stream key found in initial data, waiting for more...")
            handle_client(socket)
        end
      {:error, :closed} ->
        Logger.info("Client disconnected")
      {:error, reason} ->
        Logger.error("Error handling client: #{reason}")
    end
  end

  defp extract_stream_key(data) when is_binary(data) do
    # Simple RTMP stream key extraction
    # In real implementation, this would parse RTMP handshake properly
    case :binary.match(data, "live_km_") do
      :nomatch -> {:error, :not_found}
      {pos, _} ->
        # Extract potential stream key (simplified)
        case extract_string_from_pos(data, pos) do
          {:ok, stream_key} -> 
            # Verify stream key exists
            case Streaming.get_stream_by_key(stream_key) do
              nil -> {:error, :invalid_key}
              stream -> {:ok, stream}
            end
          error -> error
        end
    end
  end

  defp extract_string_from_pos(data, pos) do
    # Extract string until null terminator or reasonable length
    case extract_until_null(data, pos, "") do
      {key, _} when byte_size(key) > 10 -> {:ok, key}
      _ -> {:error, :not_found}
    end
  end

  defp extract_until_null(data, pos, acc) do
    if pos >= byte_size(data) do
      {acc, pos}
    else
      case :binary.at(data, pos) do
        0 -> {acc, pos + 1}
        byte -> extract_until_null(data, pos + 1, acc <> <<byte>>)
      end
    end
  end

  defp handle_stream_key(socket, stream_key) do
    case Streaming.get_stream_by_key(stream_key) do
      nil ->
        Logger.error("Invalid stream key: #{stream_key}")
        :gen_tcp.close(socket)
      stream ->
        Logger.info("Valid stream key for stream #{stream.id}")
        
        # Update stream as live
        Streaming.update_stream(stream, %{is_live: true})
        
        # Send success response
        response = <<0x01, 0x00, 0x00, 0x00>>  # Simple success response
        :gen_tcp.send(socket, response)
        
        # Keep connection alive for streaming
        keep_alive(socket, stream)
    end
  end

  defp keep_alive(socket, stream) do
    :gen_tcp.send(socket, <<0x00, 0x00, 0x00, 0x00>>)  # Keep-alive ping
    receive do
      {:tcp, ^socket, data} ->
        Logger.info("Received streaming data: #{byte_size(data)} bytes")
        keep_alive(socket, stream)
      {:tcp_closed, ^socket} ->
        Logger.info("Stream ended for #{stream.id}")
        Streaming.update_stream(stream, %{is_live: false})
      {:error, ^socket, _reason} ->
        Logger.error("Stream error for #{stream.id}")
        Streaming.update_stream(stream, %{is_live: false})
    after
      30_000 ->  # 30 second timeout
        Logger.info("Stream timeout for #{stream.id}")
        Streaming.update_stream(stream, %{is_live: false})
        :gen_tcp.close(socket)
    end
  end
end
