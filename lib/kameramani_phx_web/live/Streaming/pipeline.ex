defmodule KameramaniPhxWeb.Streaming.Pipeline do
  use Membrane.Pipeline
  import Membrane.ChildrenSpec
  require Logger

  alias Membrane.H264.Parser, as: H264Parser
  alias Membrane.HTTPAdaptiveStream.SinkBin
  alias Membrane.HTTPAdaptiveStream.HLS
  alias Membrane.HTTPAdaptiveStream.Storages.FileStorage, as: FileStorage

  def start_link(id, hls_dir) do
    # Use Membrane's start_link instead of GenServer
    Membrane.Pipeline.start_link(__MODULE__, {id, hls_dir}, name: id)
  end

  @impl true
  def handle_init(_ctx, {_id, hls_dir}) do
    Logger.info("🎬 Initializing HLS Pipeline in #{hls_dir}")

    spec = [
      # Video parser for H264 input
      child(:video_parser, %H264Parser{output_alignment: :au}),
      # HLS sink for output
      child(:sink, %SinkBin{
        manifest_module: HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %FileStorage{directory: hls_dir}
      })
    ]

    links = [
      # Connect video parser output to sink video input
      get_child(:video_parser)
      |> via_out(Pad.ref(:output))
      |> get_child(:sink)
      |> via_in(Pad.ref(:video))
    ]

    {[spec: spec, links: links], %{hls_dir: hls_dir}}
  end

  def stop_stream(id) do
    Membrane.Pipeline.terminate(id)
  end
end
