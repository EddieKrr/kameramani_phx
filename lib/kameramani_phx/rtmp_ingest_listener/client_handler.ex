defmodule KameramaniPhx.RTMPIngestListener.ClientHandler do
  require Logger

  alias KameramaniPhx.Streaming
  alias KameramaniPhx.StreamManager

  @doc """
  Handles new RTMP client connections from Membrane.RTMPServer.
  
  Called with 3 arguments: (client_ref, app, stream_key)
  Must return a client_behaviour_spec:
  - A module that implements the ClientHandler behavior
  - {module, init_opts} tuple
  """
  
  # Minimal handler that just ignores all client messages
  # The actual stream handling is done by the pipeline
  defmodule Handler do
    def handle_init(opts) do
      # If we're rejecting the connection, signal it immediately
      case opts do
        %{error: _reason} -> {:error, :unauthorized}
        _ -> {:ok, opts}
      end
    end

    def handle_data_available(_data, state) do
      # Ignore data events - the pipeline handles actual stream data via client_ref
      {:ok, state}
    end

    def handle_info(_info, state) do
      # Ignore all internal RTMPServer messages - the pipeline handles everything
      {:ok, state}
    end

    def handle_teardown(state) do
      {:ok, state}
    end
  end

  def handle_setup(client_ref, app, stream_key) do
    Logger.info("🎥 RTMP Client connected: app=#{app}, stream_key=#{stream_key}")
    
    case Streaming.get_stream_by_key(stream_key) do
      nil ->
        Logger.warning("❌ Unauthorized stream key: #{stream_key}")
        {Handler, %{error: :unauthorized}}

      stream ->
        Logger.info("✅ Valid stream found for key: #{stream_key}")
        hls_output_directory = "priv/static/live/#{stream.id}"
        File.mkdir_p!(hls_output_directory)

        # Start the RTMP ingest pipeline
        pipeline_id = String.to_atom("rtmp_pipeline_#{stream.id}")
        
        # Stop any existing pipeline for this stream (in case of reconnection)
        if existing_pid = StreamManager.get_pipeline_id(stream.id) do
          Logger.debug("Stopping existing pipeline for stream #{stream.id}")
          Membrane.Pipeline.terminate(existing_pid)
          Process.sleep(100) # Give it time to shutdown
        end
        
        case KameramaniPhx.RTMPIngestPipeline.start_link(
               pipeline_id,
               hls_output_directory,
               client_ref
             ) do
          {:ok, pid, _pid2} ->
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

            # Return the minimal handler module to keep connection alive
            # The pipeline is already receiving the stream data via client_ref
            {Handler, %{}}

          {:error, reason} ->
            Logger.error("❌ Failed to start RTMP ingest pipeline: #{inspect(reason)}")
            {Handler, %{error: :pipeline_error}}
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
