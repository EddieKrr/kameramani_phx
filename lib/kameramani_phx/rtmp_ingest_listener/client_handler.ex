defmodule KameramaniPhx.RTMPIngestListener.ClientHandler do
  require Logger

  alias KameramaniPhx.Streaming
  alias KameramaniPhx.StreamManager

  @doc """
  Handles new RTMP client connections from Membrane.RTMPServer.
  
  Called with 3 arguments: (client_ref, app, stream_key)
  Must return a client_behaviour_spec which is typically {ClientHandler, init_opts} or just ClientHandler.
  """
  def handle_setup(client_ref, app, stream_key) do
    Logger.info("🎥 RTMP Client connected: app=#{app}, stream_key=#{stream_key}")
    
    case Streaming.get_stream_by_key(stream_key) do
      nil ->
        Logger.warning("❌ Unauthorized stream key: #{stream_key}")
        {:disconnect, :unauthorized}

      stream ->
        Logger.info("✅ Valid stream found for key: #{stream_key}")
        hls_output_directory = "priv/static/live/#{stream.id}"
        File.mkdir_p!(hls_output_directory)

        # Start the RTMP ingest pipeline
        pipeline_id = String.to_atom("rtmp_pipeline_#{stream.id}")
        
        case KameramaniPhx.RTMPIngestPipeline.start_link(
               pipeline_id,
               hls_output_directory,
               client_ref
             ) do
          {:ok, pid} ->
            Logger.info("🎬 RTMP Ingest Pipeline started: #{inspect(pid)}")
            # Register stream and update status
            StreamManager.add_stream(stream.id, pid)
            {:ok, updated_stream} = Streaming.update_stream(stream, %{is_live: true})

            # Broadcast for UI updates
            Phoenix.PubSub.broadcast(
              KameramaniPhx.PubSub,
              "streams:#{updated_stream.id}",
              {:stream_status_updated, updated_stream}
            )

            # Return handler module and state
            {Membrane.RTMPServer.ClientHandler, %{stream_id: stream.id, pipeline_pid: pid}}

          {:error, reason} ->
            Logger.error("❌ Failed to start RTMP ingest pipeline: #{inspect(reason)}")
            {:disconnect, :pipeline_error}
        end
    end
  end

  def handle_teardown(stream_key, pid) do
    if stream = Streaming.get_stream_by_key(stream_key) do
      {:ok, updated_stream} = Streaming.update_stream(stream, %{is_live: false})
      StreamManager.remove_stream(stream.id)

      Phoenix.PubSub.broadcast(
        KameramaniPhx.PubSub,
        "streams:#{updated_stream.id}",
        {:stream_status_updated, updated_stream}
      )
    end

    if Process.alive?(pid), do: Membrane.Pipeline.terminate(pid)
    :ok
  end
end
