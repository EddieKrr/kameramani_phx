defmodule KameramaniPhx.StreamManager do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_stream(stream_id, pipeline_id) do
    Agent.update(__MODULE__, fn state -> Map.put(state, stream_id, pipeline_id) end)

    start_thumbnail_capture(stream_id)

    Phoenix.PubSub.broadcast(
      KameramaniPhx.PubSub,
      "stream_state:#{stream_id}",
      {:stream_status, :online}
    )
  end

  def remove_stream(stream_id) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, stream_id) end)

    stop_thumbnail_capture(stream_id)

    Phoenix.PubSub.broadcast(
      KameramaniPhx.PubSub,
      "stream_state:#{stream_id}",
      {:stream_status, :offline}
    )
  end

  def get_pipeline_id(stream_id) do
    Agent.get(__MODULE__, fn state -> Map.get(state, stream_id) end)
  end

  def is_stream_running?(stream_id) do
    Agent.get(__MODULE__, fn state -> Map.has_key?(state, stream_id) end)
  end

  defp start_thumbnail_capture(stream_id) do
    if Process.whereis(KameramaniPhx.ThumbnailSupervisor) do
      case DynamicSupervisor.start_child(
             KameramaniPhx.ThumbnailSupervisor,
             {KameramaniPhx.ThumbnailGenerator, stream_id}
           ) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        {:error, _reason} -> :error
      end
    else
      :error
    end
  end

  defp stop_thumbnail_capture(stream_id) do
    if Process.whereis(KameramaniPhx.ThumbnailRegistry) do
      case Registry.lookup(KameramaniPhx.ThumbnailRegistry, stream_id) do
        [{pid, _}] ->
          DynamicSupervisor.terminate_child(KameramaniPhx.ThumbnailSupervisor, pid)

        [] ->
          :ok
      end
    else
      :ok
    end
  end
end
