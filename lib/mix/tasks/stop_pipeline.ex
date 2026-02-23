defmodule Mix.Tasks.StopPipeline do
  use Mix.Task

  @shortdoc "Stops a streaming pipeline for a given stream ID"

  @moduledoc """
  Stops an HLS streaming pipeline for a specific stream.

  ## Usage

      mix stop_pipeline <stream_id>

  ## Examples

      mix stop_pipeline 40852182-b0c9-4998-896a-26bd347da4ee

  """

  alias KameramaniPhx.Streaming
  alias KameramaniPhxWeb.Streaming.Pipeline
  alias KameramaniPhx.StreamManager

  @impl true
  def run([stream_id]) do
    IO.puts("Stopping pipeline for stream: #{stream_id}")

    # Check if stream exists
    case Streaming.get_stream!(stream_id) do
      nil ->
        IO.puts("Error: Stream #{stream_id} not found")
        :error
      stream ->
        # Get pipeline ID
        pipeline_id = String.to_atom("stream_pipeline_#{stream_id}")
        
        case StreamManager.get_pipeline_id(stream_id) do
          nil ->
            IO.puts("❌ No active pipeline found for stream #{stream_id}")
            :error
          ^pipeline_id ->
            # Stop the pipeline
            Pipeline.stop_stream(pipeline_id)
            
            # Unregister the stream
            StreamManager.remove_stream(stream_id)
            
            # Update stream status
            Streaming.update_stream(stream, %{is_live: false})
            
            IO.puts("✅ Pipeline stopped successfully for stream #{stream_id}")
            :ok
          _other_pipeline_id ->
            IO.puts("❌ Pipeline mismatch for stream #{stream_id}")
            :error
        end
    end
  end

  def run([]) do
    IO.puts("Error: Stream ID is required")
    IO.puts("Usage: mix stop_pipeline <stream_id>")
    IO.puts("")
    IO.puts("Active pipelines:")
    
    # List all active streams
    case Streaming.list_streams() do
      [] ->
        IO.puts("  No streams found")
      streams ->
        Enum.each(streams, fn stream ->
          pipeline_id = StreamManager.get_pipeline_id(stream.id)
          status = if pipeline_id, do: "🟢 RUNNING", else: "⚫ STOPPED"
          IO.puts("  #{stream.id} - #{stream.title} #{status}")
        end)
    end
  end
end
