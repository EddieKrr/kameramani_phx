defmodule KameramaniPhx.StreamManager do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_stream(stream_id, pipeline_id) do
    Agent.update(__MODULE__, fn state -> Map.put(state, stream_id, pipeline_id) end)
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "stream_state:#{stream_id}", {:stream_status, :online})
  end

  def remove_stream(stream_id) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, stream_id) end)
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "stream_state:#{stream_id}", {:stream_status, :offline})
  end

  def get_pipeline_id(stream_id) do
    Agent.get(__MODULE__, fn state -> Map.get(state, stream_id) end)
  end

  def is_stream_running?(stream_id) do
    Agent.get(__MODULE__, fn state -> Map.has_key?(state, stream_id) end)
  end
end
