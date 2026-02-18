defmodule KameramaniPhxWeb.Streaming.Pipeline do
  use Membrane.Bin,
    input_pads: [
      audio: [demand_mode: :auto],
      video: [demand_mode: :auto]
    ]
  import Membrane.ChildrenSpec
  # import Membrane.Bin # Removed - input/1 is implicitly handled by input_pads

  # These aliases ensure the compiler knows exactly where to look
  alias Membrane.H264.Parser, as: H264Parser
  alias Membrane.HTTPAdaptiveStream.SinkBin
  alias Membrane.HTTPAdaptiveStream.HLS
  alias Membrane.HTTPAdaptiveStream.Storages.FileStorage, as: FileStorage

  def start_link(pipeline_id, hls_output_directory) do
    GenServer.start_link(__MODULE__, [hls_output_directory: hls_output_directory], name: pipeline_id)
  end

  @impl true
  def handle_init(_ctx, init_args) do
    hls_output_directory = Keyword.fetch!(init_args, :hls_output_directory)

    spec = [
      # Audio path: from external input pad -> sink:input(audio)
      # Reference the declared input pad directly
      via_in(Membrane.Pad.ref(:input, :audio),
        options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(4)]
      )
      |> child(:sink, %SinkBin{
        manifest_module: HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %FileStorage{directory: hls_output_directory}
      }),

      # Video path: from external input pad -> parser:input -> sink:input(video)
      # Reference the declared input pad directly
      child(:parser, %H264Parser{output_alignment: :au})
      |> via_in(Membrane.Pad.ref(:input, :video),
        options: [encoding: :H264, segment_duration: Membrane.Time.seconds(4)]
      )
      |> get_child(:sink)
    ]

    {[spec: spec], %{}}
  end

  def stop_stream(pipeline_id) do
    GenServer.stop(pipeline_id)
  end
end
