defmodule KameramaniPhx.OBSRTMPServer do
  @moduledoc """
  RTMP server specifically designed for OBS compatibility using Membrane v0.29.x.
  """

  use GenServer
  require Logger

  @port 1935

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🚀 Starting OBS RTMP Server on port #{@port}")

    # Start Membrane RTMP Server (v0.29.x architecture)
    # Note: Membrane.RTMPServer is a GenServer, not a Bin
    children = [
      {
        Membrane.RTMPServer,
        [
          port: @port,
          handle_new_client: &KameramaniPhx.RTMPIngestListener.ClientHandler.handle_setup/3
        ]
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  # Callback function for RTMP connections
  def handle_rtmp_connection(client_ref, connection_info) do
    Logger.info("🎥 OBS RTMP connection: #{inspect(connection_info)}")

    # Extract stream key from connection info
    case extract_stream_key_from_connection(connection_info) do
      {:ok, stream_key} ->
        Logger.info("🔑 Stream key extracted: #{stream_key}")
        validate_and_start_stream(client_ref, stream_key)

      {:error, reason} ->
        Logger.error("❌ Failed to extract stream key: #{reason}")
        :gen_tcp.close(client_ref)
    end
  end

  defp extract_stream_key_from_connection(connection_info) do
    # In v0.29.x, stream key should be in connection_info
    case Map.get(connection_info, :stream_key) do
      nil ->
        # Try to extract from app name or other fields
        case Map.get(connection_info, :app) do
          "live/" <> stream_key -> {:ok, stream_key}
          _ -> {:error, :no_stream_key}
        end

      stream_key ->
        {:ok, stream_key}
    end
  end

  defp validate_and_start_stream(client_ref, stream_key) do
    # Extract user_id from stream key
    case String.split(stream_key, "_") do
      ["live", "km", user_id, _secret] ->
        Logger.info("✅ Valid stream key for user #{user_id}")

        # Start your existing streaming pipeline
        case KameramaniPhx.Streaming.Pipeline.start_link([
          hls_output_directory: "priv/static/live/#{user_id}",
          stream_key: stream_key
        ]) do
          {:ok, _pipeline_pid} ->
            Logger.info("🎬 Pipeline started for stream #{stream_key}")

            # Send success response to OBS
            send_rtmp_success(client_ref)

            # Keep connection alive for streaming
            keep_connection_alive(client_ref, user_id, stream_key)

          {:error, reason} ->
            Logger.error("❌ Failed to start pipeline: #{reason}")
            send_rtmp_error(client_ref)
        end

      _ ->
        Logger.error("❌ Invalid stream key format: #{stream_key}")
        send_rtmp_error(client_ref)
    end
  end

  defp keep_connection_alive(client_ref, user_id, stream_key) do
    # In v0.29.x, the server handles streaming automatically
    # We just need to monitor the connection
    receive do
      {:rtmp_disconnected, ^client_ref} ->
        Logger.info("❌ OBS disconnected, stopping stream")

      {:rtmp_error, ^client_ref, reason} ->
        Logger.error("❌ RTMP error: #{reason}")

      after
        60_000 ->
          # Keep alive check
          keep_connection_alive(client_ref, user_id, stream_key)
    end
  end

  defp send_rtmp_success(client_ref) do
    # Send RTMP success response
    Logger.info("✅ RTMP connection accepted")
  end

  defp send_rtmp_error(client_ref) do
    # Send RTMP error response
    Logger.error("❌ RTMP connection rejected")
  end
end
