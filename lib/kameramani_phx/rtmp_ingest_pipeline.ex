defmodule KameramaniPhx.RTMPIngestPipeline do
  use Membrane.Pipeline
  import Membrane.ChildrenSpec
  require Logger
  require Membrane.Time

  def start_link(args), do: Membrane.Pipeline.start_link(__MODULE__, args)

  @impl true
  def handle_init(_ctx, {hls_dir, client_ref}) do
    spec = [
      child(:src, %Membrane.RTMP.SourceBin{client_ref: client_ref}),
      child(:sink, %Membrane.HTTPAdaptiveStream.SinkBin{
        manifest_name: "index",
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: hls_dir},
        mode: :live,
        hls_mode: :separate_av
      }),

      #  Wire the Video track
      get_child(:src)
      |> via_out(:video)
      |> via_in(Pad.ref(:input, :video),
        options: [
          encoding: :H264,
          # take 4s captures for each segment
          segment_duration: Membrane.Time.seconds(2)
        ]
      )
      |> get_child(:sink),
      get_child(:src)
      |> via_out(:audio)
      |> via_in(Pad.ref(:input, :audio),
        options: [
          encoding: :AAC,
          segment_duration: Membrane.Time.seconds(2)
        ]
      )
      |> get_child(:sink)
    ]

    {[spec: spec], %{}}
  end

  @impl true
  def handle_element_end_of_stream(:src, _pad, _ctx, state) do
    Logger.info("📹 Stream ended. Shutting down pipeline.")
    {[terminate: :normal], state}
  end
end
