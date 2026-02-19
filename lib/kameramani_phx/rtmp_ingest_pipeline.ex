defmodule KameramaniPhx.RTMPIngestPipeline do
  @moduledoc """
  Membrane Pipeline for ingesting RTMP streams and outputting HLS.
  
  Receives H264 video and AAC audio from the RTMP source,
  demuxes them, parses them, and outputs HLS playlist and segments.
  """
  use Membrane.Pipeline
  import Membrane.ChildrenSpec
  require Logger

  alias Membrane.HTTPAdaptiveStream.SinkBin
  alias Membrane.HTTPAdaptiveStream.HLS
  alias Membrane.HTTPAdaptiveStream.Storages.FileStorage, as: FileStorage
  alias Membrane.RTMP.SourceBin

  def start_link(id, hls_dir, client_ref) do
    Membrane.Pipeline.start_link(__MODULE__, {hls_dir, client_ref}, name: id)
  end

  @impl true
  def handle_init(_ctx, {hls_dir, client_ref}) do
    Logger.info("🎬 Initializing RTMP Ingest Pipeline in #{hls_dir}")

    spec = [
      # RTMP source - receives from client_ref
      child(:rtmp_source, %SourceBin{
        client_ref: client_ref
      }),
      # HLS sink for output
      child(:hls_sink, %SinkBin{
        manifest_module: HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %FileStorage{directory: hls_dir}
      })
    ]

    {[spec: spec], %{video_linked: false, audio_linked: false}}
  end

  @impl true
  def handle_child_notification(
        {:new_stream, pad_ref, _format},
        :rtmp_source,
        _ctx,
        state
      ) do
    # SourceBin notifies us when new streams are available
    Logger.info("📹 New stream from RTMP source on pad: #{inspect(pad_ref)}")
    {[], state}
  end

  def handle_child_notification(_notification, _child, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_element_start_of_stream(:rtmp_source, pad, _ctx, state) do
    Logger.info("▶️ Stream started on pad: #{inspect(pad)}")
    
    pad_name = Membrane.Pad.name_by_ref(pad)
    new_state = 
      case pad_name do
        :video -> %{state | video_linked: true}
        :audio -> %{state | audio_linked: true}
        _ -> state
      end
    
    # Link the pad dynamically
    spec =
      get_child(:rtmp_source)
      |> via_out(pad)
      |> get_child(:hls_sink)
      |> via_in(Pad.ref(pad_name))

    {[spec: spec], new_state}
  end

  @impl true
  def handle_element_end_of_stream(:rtmp_source, _pad, _ctx, state) do
    Logger.info("📹 RTMP stream ended")
    {[terminate: :normal], state}
  end

  def handle_element_end_of_stream(_child, _pad, _ctx, state) do
    {[], state}
  end
end
