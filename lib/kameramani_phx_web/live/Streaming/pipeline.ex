defmodule KameramaniPhxWeb.Streaming.Pipeline do
  use Membrane.Pipeline
  import Membrane.ChildrenSpec
  import Membrane.Pad # New import

  # These aliases ensure the compiler knows exactly where to look
  alias Membrane.RTMP.SourceBin
  alias Membrane.H264.Parser, as: H264Parser
  alias Membrane.HTTPAdaptiveStream.SinkBin
  alias Membrane.HTTPAdaptiveStream.HLS
  alias Membrane.HTTPAdaptiveStream.Storages.FileStorage, as: FileStorage

  def start() do
    start_link(:my_pipeline, [])
  end

  def start_link(name, opts) do
    Membrane.Pipeline.start_link(__MODULE__, name, opts)
  end

  @impl true
  def handle_init(_ctx, _opts) do
    spec = [
      # Audio path: src:audio -> sink:input(audio)
      child(:src, %SourceBin{
        url: "rtmp://127.0.0.1:1935/live/cube_test"
      })
      |> via_out(:audio)
      |> via_in(Pad.ref(:input, :audio),
        options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(4)]
      )
      |> child(:sink, %SinkBin{
        manifest_module: HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %FileStorage{directory: "priv/static/live/cube"}
      }),

      # Video path: src:video -> parser:input -> sink:input(video)
      get_child(:src)
      |> via_out(:video)
      |> child(:parser, %H264Parser{output_alignment: :au})
      |> via_in(Pad.ref(:input, :video),
        options: [encoding: :H264, segment_duration: Membrane.Time.seconds(4)]
      )
      |> get_child(:sink)
    ]

    {[spec: spec], %{}}
  end
end
