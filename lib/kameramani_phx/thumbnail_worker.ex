defmodule KameramaniPhx.ThumbnailGenerator do
  use GenServer
  require Logger

  alias KameramaniPhx.StreamManager

  @initial_delay_ms 1_000

  def start_link(stream_id) when is_binary(stream_id) do
    GenServer.start_link(__MODULE__, stream_id, name: via(stream_id))
  end

  def child_spec(stream_id) do
    %{
      id: {__MODULE__, stream_id},
      start: {__MODULE__, :start_link, [stream_id]},
      restart: :transient
    }
  end

  @impl true
  def init(stream_id) do
    Process.send_after(self(), :capture, @initial_delay_ms)
    {:ok, %{stream_id: stream_id, in_progress?: false}}
  end

  @impl true
  def handle_info(:capture, %{stream_id: stream_id, in_progress?: true} = state) do
    schedule_next_capture()
    {:noreply, state}
  end

  def handle_info(:capture, %{stream_id: stream_id} = state) do
    if StreamManager.is_stream_running?(stream_id) do
      parent = self()

      Task.start(fn ->
        result = capture_thumbnail(stream_id)
        send(parent, {:capture_done, result})
      end)

      {:noreply, %{state | in_progress?: true}}
    else
      {:stop, :normal, state}
    end
  end

  @impl true
  def handle_info({:capture_done, _result}, state) do
    schedule_next_capture()
    {:noreply, %{state | in_progress?: false}}
  end

  defp schedule_next_capture do
    Process.send_after(self(), :capture, capture_interval_ms())
  end

  defp capture_interval_ms do
    Application.get_env(:kameramani_phx, :thumbnail_capture_interval_ms, 15_000)
  end

  defp capture_thumbnail(stream_id) do
    playlist_path = live_playlist_path(stream_id)
    output_path = thumbnail_output_path(stream_id)

    with true <- File.exists?(playlist_path),
         :ok <- ensure_thumbnail_dir(output_path),
         {_, 0} <- run_ffmpeg(playlist_path, output_path) do
      :ok
    else
      false ->
        :playlist_missing

      {:error, reason} ->
        Logger.warning("Thumbnail dir error for stream #{stream_id}: #{inspect(reason)}")
        {:error, reason}

      {output, status} ->
        Logger.warning(
          "The thumbnail failed for stream #{stream_id} (exit #{status}): #{output}"
        )

        {:error, :ffmpeg_failed}
    end
  end

  defp live_playlist_path(stream_id) do
    Path.join([:code.priv_dir(:kameramani_phx), "static", "live", stream_id, "index.m3u8"])
    |> to_string()
  end

  defp thumbnail_output_path(stream_id) do
    Path.join([:code.priv_dir(:kameramani_phx), "static", "thumbnails", "#{stream_id}.jpg"])
    |> to_string()
  end

  defp ensure_thumbnail_dir(output_path) do
    output_path |> Path.dirname() |> File.mkdir_p()
  end

  defp run_ffmpeg(playlist_path, output_path) do
    args = [
      "-hide_banner",
      "-loglevel",
      "error",
      "-nostdin",
      "-y",
      "-i",
      playlist_path,
      "-frames:v",
      "1",
      "-q:v",
      "5",
      output_path
    ]

    System.cmd("ffmpeg", args, stderr_to_stdout: true)
  end

  defp via(stream_id) do
    {:via, Registry, {KameramaniPhx.ThumbnailRegistry, stream_id}}
  end
end
