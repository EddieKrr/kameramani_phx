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

    links = [
      # Connect RTMP source video output to HLS sink
      get_child(:rtmp_source)
      |> via_out(Pad.ref(:video))
      |> get_child(:hls_sink)
      |> via_in(Pad.ref(:video)),
      # Connect RTMP source audio output to HLS sink
      get_child(:rtmp_source)
      |> via_out(Pad.ref(:audio))
      |> get_child(:hls_sink)
      |> via_in(Pad.ref(:audio))
    ]

    {[spec: spec, links: links], %{}}
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
