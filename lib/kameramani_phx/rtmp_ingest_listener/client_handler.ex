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
      Logger.warn("[ClientHandler] RTMP client teardown: #{inspect(state)}")
      {:ok, state}
    end
  end

  def handle_setup(client_ref, app, stream_key) do
    Logger.debug("[ClientHandler] handle_setup/3 called with client_ref=#{inspect(client_ref)}, app=#{inspect(app)}, stream_key=#{inspect(stream_key)}")
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

        # Ensure any existing pipeline for this stream is terminated before starting a new one
        case Process.whereis(pipeline_id) do
          nil ->
            Logger.debug("No existing pipeline found for stream #{stream.id}")

          existing_pid ->
            Logger.info("Terminating existing pipeline #{inspect(existing_pid)} for stream #{stream.id}")
            Process.exit(existing_pid, :shutdown)
            # Give it a moment to clean up
            Process.sleep(100)
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
