defmodule KameramaniPhx.RTMPIngestListener.ClientHandler do
  require Logger

  alias KameramaniPhx.Streaming
  alias KameramaniPhxWeb.Streaming.Pipeline
  alias KameramaniPhx.StreamManager
  # alias Membrane.RTMP.SourceBin # Removed, not directly used here
  # alias KameramaniPhx.PubSub # Removed, not directly used here

  def handle_setup(stream_key, opts) do
    # This is called by the SourceBin when a new client connects
    Logger.info("RTMP Client connected for stream_key: #{stream_key}, opts: #{inspect(opts)}")

    case Streaming.get_stream_by_key(stream_key) do
      nil ->
        Logger.warning("No stream found for key: #{stream_key}. Disconnecting client.")
        {:disconnect, :no_stream_found}

      stream ->
        # Generate a unique pipeline ID for this stream session
        pipeline_id = "rtmp_pipeline_#{stream.id}_#{System.unique_integer([:positive])}"
        hls_output_directory = "priv/static/live/#{stream.id}"

        # Start the actual streaming pipeline (without RTMP.SourceBin, as it's handled by this listener)
        case Pipeline.start_link(pipeline_id, hls_output_directory) do
          {:ok, pid} ->
            StreamManager.add_stream(stream.id, pid)
            # Update stream status in DB (e.g., is_live: true)
            {:ok, updated_stream} = Streaming.update_stream(stream, %{is_live: true})
            # Broadcast status update
            Phoenix.PubSub.broadcast(
              KameramaniPhx.PubSub,
              "streams:#{updated_stream.id}",
              "stream_status_updated",
              updated_stream
            )

            Logger.info(
              "Pipeline #{pipeline_id} started for stream #{stream.id}. PID: #{inspect(pid)}"
            )

            # Return the PID of the spawned pipeline, which the SourceBin will send buffers to
            {:ok, pid}

          {:error, reason} ->
            Logger.error("Failed to start pipeline for stream #{stream.id}: #{inspect(reason)}")
            {:disconnect, :pipeline_start_failed}
        end
    end
  end

  def handle_teardown(stream_key, pid) do
    Logger.info("RTMP Client disconnected for stream_key: #{stream_key}, PID: #{inspect(pid)}")

    case Streaming.get_stream_by_key(stream_key) do
      nil ->
        Logger.warning("No stream found for key: #{stream_key} during teardown.")

      stream ->
        # Update stream status in DB (e.g., is_live: false)
        {:ok, updated_stream} = Streaming.update_stream(stream, %{is_live: false})
        # Broadcast status update
        Phoenix.PubSub.broadcast(
          KameramaniPhx.PubSub,
          "streams:#{updated_stream.id}",
          "stream_status_updated",
          updated_stream
        )

        StreamManager.remove_stream(stream.id)
    end

    # Optionally stop the pipeline if it's still running
    # Use GenServer.stop as Pipeline is now a Bin (GenServer)
    GenServer.stop(pid)
    :ok
  end
end
