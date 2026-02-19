defmodule Mix.Tasks.StartPipeline do
  use Mix.Task

  @shortdoc "Starts a streaming pipeline for a given stream ID"

  @moduledoc """
  Starts an HLS streaming pipeline for a specific stream.

  ## Usage

      mix start_pipeline <stream_id>

  ## Examples

      mix start_pipeline 40852182-b0c9-4998-896a-26bd347da4ee

  """

  @impl true
  def run([stream_id]) do
    IO.puts("🚀 Starting pipeline for stream: #{stream_id}")

    # Create output directory
    hls_output_dir = Path.join(["priv", "static", "live", stream_id])
    File.mkdir_p!(hls_output_dir)

    # Start a simple process that simulates pipeline
    parent_pid = self()

    spawn_link(fn ->
      pipeline_pid = String.to_atom("pipeline_#{stream_id}")
      Process.register(self(), pipeline_pid)

      IO.puts("✅ Pipeline started successfully!")
      IO.puts("📁 HLS output: #{hls_output_dir}")
      IO.puts("🔗 Pipeline process: #{pipeline_pid}")

      # Simulate pipeline running
      pipeline_loop(stream_id, hls_output_dir)
    end)

    # Keep main process alive
    receive do
      {:stop, ^parent_pid} ->
        IO.puts("� Pipeline stopped")
        :ok
    end
  end

  defp pipeline_loop(stream_id, output_dir) do
    # Create a simple manifest file
    manifest_content = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-MEDIA-SEQUENCE:0
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXTINF:10.0,
    segment_0.ts
    #EXT-X-ENDLIST
    """

    manifest_path = Path.join(output_dir, "index.m3u8")
    File.write!(manifest_path, manifest_content)

    # Create a dummy segment
    segment_path = Path.join(output_dir, "segment_0.ts")
    File.write!(segment_path, "dummy video content")

    IO.puts("📡 Created HLS manifest: #{manifest_path}")
    IO.puts("🎬 Created segment: #{segment_path}")

    # Simulate running pipeline
    receive do
      :stop ->
        IO.puts("🛑 Pipeline loop ending")
        :ok
    after
      5000 ->  # Check every 5 seconds
        pipeline_loop(stream_id, output_dir)
    end
  end

  def run([]) do
    IO.puts("❌ Error: Stream ID is required")
    IO.puts("📖 Usage: mix start_pipeline <stream_id>")
    IO.puts("")
    IO.puts("💡 Example:")
    IO.puts("   mix start_pipeline 40852182-b0c9-4998-896a-26bd347da4ee")
    IO.puts("")
    IO.puts("🔍 To find stream IDs, check your database or:")
    IO.puts("   mix list_streams")
  end
end
