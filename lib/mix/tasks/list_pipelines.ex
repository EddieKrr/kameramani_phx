defmodule Mix.Tasks.ListPipelines do
  use Mix.Task

  @shortdoc "Lists all streaming pipelines and their status"

  @moduledoc """
  Lists all streams and their pipeline status.

  ## Usage

      mix list_pipelines

  ## Examples

      mix list_pipelines

  """

  alias KameramaniPhx.Streaming
  alias KameramaniPhx.StreamManager

  @impl true
  def run(_args) do
    IO.puts("📺 Streaming Pipelines Status")
    IO.puts("=" <> String.duplicate("=", 50))

    case Streaming.list_streams() do
      [] ->
        IO.puts("  No streams found")

      streams ->
        Enum.each(streams, fn stream ->
          pipeline_id = StreamManager.get_pipeline_id(stream.id)

          # Stream info
          IO.puts("")
          IO.puts("🎬 Stream: #{stream.title}")
          IO.puts("🆔 ID: #{stream.id}")
          IO.puts("🔑 Key: #{stream.stream_key}")

          # Pipeline status
          case pipeline_id do
            nil ->
              IO.puts("⚫ Pipeline: STOPPED")

            _pid ->
              case Process.alive?(pipeline_id) do
                true -> IO.puts("🟢 Pipeline: RUNNING")
                false -> IO.puts("⚠️  Pipeline: CRASHED")
              end
          end

          # Stream status
          stream_status = if stream.is_live, do: "🔴 LIVE", else: "⚫ OFFLINE"
          IO.puts("📡 Status: #{stream_status}")

          # Categories and tags
          if stream.category_id do
            IO.puts("📁 Category: #{stream.category_id}")
          end

          if stream.tags && length(stream.tags) > 0 do
            IO.puts("🏷️  Tags: #{Enum.join(stream.tags, ", ")}")
          end

          IO.puts(String.duplicate("-", 50))
        end)
    end
  end
end
