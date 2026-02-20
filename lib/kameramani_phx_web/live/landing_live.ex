defmodule KameramaniPhxWeb.LandingLive do
  use KameramaniPhxWeb, :live_view
  import Ecto.Query
  import KameramaniPhxWeb.SidebarComponents
  import KameramaniPhxWeb.CardComponents
  alias KameramaniPhxWeb.DummyData

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    # Fetch only streams where is_live is true
    streams = KameramaniPhx.Repo.all(
      from s in KameramaniPhx.Streaming.Stream,
      where: s.is_live == true,
      preload: [:user]
    )

    # Subscribe to each stream to get live updates
    if connected?(socket) do
      # Subscribe to a general 'streams' topic to know when NEW streams go live
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:all")

      # Subscribe to existing live streams to know when they go offline
      Enum.each(streams, fn s ->
        Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:#{s.id}")
      end)
    end

    # Map database streams to the format expected by the card component
    streams_data = Enum.map(streams, &map_stream/1)

    {:ok, assign(socket, streams_data: streams_data)}
  end

  def handle_info({:stream_status_updated, updated_stream}, socket) do
    # Reload stream with user
    updated_stream = KameramaniPhx.Repo.preload(updated_stream, :user)

    streams_data = if updated_stream.is_live do
      # Add or update in list
      existing_ids = Enum.map(socket.assigns.streams_data, & &1.id)

      if updated_stream.id in existing_ids do
        Enum.map(socket.assigns.streams_data, fn
          s when s.id == updated_stream.id -> map_stream(updated_stream)
          s -> s
        end)
      else
        # Subscribe to this specific stream's future updates if it's new
        if connected?(socket), do: Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:#{updated_stream.id}")
        [map_stream(updated_stream) | socket.assigns.streams_data]
      end
    else
      # Remove from list if no longer live
      Enum.reject(socket.assigns.streams_data, &(&1.id == updated_stream.id))
    end

    {:noreply, assign(socket, streams_data: streams_data)}
  end

  defp map_stream(s) do
    %{
      id: s.id,
      stream_name: s.title,
      streamer: s.user.username,
      category: s.category || "Just Chatting",
      tags: Enum.join(s.tags || [], ", "),
      viewer_count: 0,
      avatar: s.user.profile_picture || "https://ui-avatars.com/api/?background=random",
      is_live: s.is_live
    }
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Landing Page")}
  end
end
