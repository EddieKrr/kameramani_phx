defmodule KameramaniPhx.RTMPIngestListener.ClientHandler do
  require Logger
  alias KameramaniPhx.Streaming
  alias KameramaniPhx.StreamManager

  def handle_new_client(client_ref, _app, stream_key) do
    Logger.info("🎥 OBS connection attempt with key: #{stream_key}")

    case Streaming.get_stream_by_key(stream_key) do
      nil ->
        Logger.warning("❌ Unauthorized stream key: #{stream_key}")
        nil

      stream ->
        hls_dir = "priv/static/live/#{stream.id}"
        File.mkdir_p!(hls_dir)

        {:ok, _sup, pipeline_pid} = KameramaniPhx.RTMPIngestPipeline.start_link({hls_dir, client_ref})

        StreamManager.add_stream(stream.id, pipeline_pid)
        Streaming.update_stream(stream, %{is_live: true})

        # Return our custom Handler and initialize state with a nil source_pid
        {__MODULE__.Handler, %{source_pid: nil, stream_id: stream.id}}
    end
  end

  # --- The Actual Handler Sub-Module ---
  defmodule Handler do
    @behaviour Membrane.RTMPServer.ClientHandler
    require Logger
    alias KameramaniPhx.Streaming
    alias KameramaniPhx.StreamManager

    @impl true
    def handle_init(opts), do: opts

    # 1. The Pipeline's SourceBin sends this message. We save its PID.
    # CRITICAL FIX: Return state DIRECTLY, do not wrap in {:ok, state}
    @impl true
    def handle_info({:send_me_data, source_pid}, state) do
      Logger.info("✅ RTMP Handler successfully linked to Pipeline Source")
      %{state | source_pid: source_pid}
    end

    @impl true
    def handle_info(_message, state), do: state

    # 2. OBS sends video/audio data. We forward it to the saved Pipeline PID.
    # CRITICAL FIX: Return state DIRECTLY
    @impl true
    def handle_data_available(data, %{source_pid: source_pid} = state) when not is_nil(source_pid) do
      # THE MAGIC FIX: Changed :rtmp_data to :data
      send(source_pid, {:data, data})
      state
    end

    @impl true
    def handle_data_available(_data, state) do
      # Safely drop data if it arrives a millisecond before the pipeline is ready
      state
    end

    @impl true
    def handle_delete_stream(%{stream_id: stream_id} = state) do
      Logger.info("🛑 OBS requested to stop the stream (deleteStream).")
      perform_cleanup(stream_id)
      state
    end

    @impl true
    def handle_delete_stream(state), do: state

    @impl true
    def handle_teardown(%{stream_id: stream_id} = _state) do
      Logger.info("📹 RTMP connection teardown.")
      perform_cleanup(stream_id)
      :ok
    end

    @impl true
    def handle_teardown(_state), do: :ok

    @impl true
    def handle_connection_closed(state) do
      # If handle_teardown hasn't been called, this might be a crash/forced disconnect
      if stream_id = Map.get(state, :stream_id) do
        perform_cleanup(stream_id)
      end
      state
    end

    defp perform_cleanup(stream_id) do
      # Only perform cleanup if the stream is currently considered running in StreamManager
      if StreamManager.is_stream_running?(stream_id) do
        Logger.info("🧹 Cleaning up stream #{stream_id}...")
        
        # Update DB - This will also broadcast :stream_status_updated to StudioLive
        case Streaming.get_stream!(stream_id) do
          stream -> Streaming.update_stream(stream, %{is_live: false})
        end

        # Remove from Manager - This will broadcast :stream_status to ChatLive viewers
        StreamManager.remove_stream(stream_id)
      end
    end
  end
end
