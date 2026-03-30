defmodule KameramaniPhxWeb.LandingLive do
  use KameramaniPhxWeb, :live_view
  import Ecto.Query
  import KameramaniPhxWeb.SidebarComponents
  import KameramaniPhxWeb.CardComponents
  import KameramaniPhxWeb.VideoComponents
  alias KameramaniPhxWeb.Presence
  alias KameramaniPhx.Streaming

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    # Fetch only streams where is_live is true
    streams =
      KameramaniPhx.Repo.all(
        from s in Streaming.Stream,
          where: s.is_live == true,
          preload: [:user],
          limit: 5
      )

    # Subscribe to each stream to get live updates
    if connected?(socket) do
      # Subscribe to a general 'streams' topic to know when NEW streams go live
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:all")

      # Subscribe to existing live streams to know when they go offline
      # AND their viewer count changes
      Enum.each(streams, fn s ->
        KameramaniPhxWeb.Endpoint.subscribe("stream_viewers:#{s.id}")
      end)
    end

    # Map database streams to the format expected by the card component
    streams_data = streams_to_cards(streams)

    # Fetch recommended streamers for the sidebar
    recommended_streams =
      KameramaniPhx.Repo.all(
        from s in KameramaniPhx.Streaming.Stream,
          where: s.is_live == true,
          limit: 10,
          preload: [:user]
      )
      |> Enum.map(fn s ->
        count = Presence.list("stream_viewers:#{s.id}") |> map_size()

        %{
          name: s.user.username,
          game: s.category || "Just Chatting",
          viewer_count: count,
          is_verified: s.user.is_verified,
          src:
            if(s.user.profile_picture in [nil, ""],
              do: "https://ui-avatars.com/api/?name=#{s.user.username}&background=random",
              else: s.user.profile_picture
            )
        }
      end)

    {:ok,
     socket
     |> assign(
       search_form: to_form(%{"query" => ""}, as: :search),
       streams_data: streams_data,
       all_streams_data: streams_data,
       recommended_streams: recommended_streams,
       carousel_index: 0
     )}
  end

  def handle_event("next_slide", _, socket) do
    total = length(socket.assigns.streams_data)
    next_idx = if total > 0, do: rem(socket.assigns.carousel_index + 1, total), else: 0
    {:noreply, assign(socket, carousel_index: next_idx)}
  end

  def handle_event("prev_slide", _, socket) do
    total = length(socket.assigns.streams_data)
    prev_idx = if total > 0, do: rem(socket.assigns.carousel_index - 1 + total, total), else: 0
    {:noreply, assign(socket, carousel_index: prev_idx)}
  end

  def handle_event("set_slide", %{"index" => index}, socket) do
    {:noreply, assign(socket, carousel_index: String.to_integer(index))}
  end

  def handle_event("search_username", %{"search" => %{"query" => query}}, socket) do
    query = String.trim(query)

    streams_data =
      if query == "" do
        socket.assigns.all_streams_data
      else
        query
        |> Streaming.list_live_streams_by_username()
        |> streams_to_cards()
      end

    {:noreply,
     socket
     |> assign(streams_data: streams_data)
     |> assign(search_form: to_form(%{"query" => query}, as: :search))}
  end

  def handle_info({:stream_status_updated, updated_stream}, socket) do
    # Reload stream with user
    updated_stream = KameramaniPhx.Repo.preload(updated_stream, :user)

    streams_data =
      if updated_stream.is_live do
        # Add or update in list
        existing_ids = Enum.map(socket.assigns.streams_data, & &1.id)

        if updated_stream.id in existing_ids do
          Enum.map(socket.assigns.streams_data, fn
            s when s.id == updated_stream.id ->
              count = Presence.list("stream_viewers:#{updated_stream.id}") |> map_size()
              map_stream(updated_stream, count)

            s ->
              s
          end)
        else
          # Subscribe to this specific stream's future updates if it's new
          if connected?(socket) do
            Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:#{updated_stream.id}")
            KameramaniPhxWeb.Endpoint.subscribe("stream_viewers:#{updated_stream.id}")
          end

          count = Presence.list("stream_viewers:#{updated_stream.id}") |> map_size()
          [map_stream(updated_stream, count) | socket.assigns.streams_data]
        end
      else
        # Remove from list if no longer live
        Enum.reject(socket.assigns.streams_data, &(&1.id == updated_stream.id))
      end

    {:noreply, assign(socket, streams_data: streams_data)}
  end

  # handling the viewer count updates via Presence
  def handle_info(
        %Phoenix.Socket.Broadcast{topic: "stream_viewers:" <> stream_id, event: "presence_diff"},
        socket
      ) do
    new_count = Presence.list("stream_viewers:#{stream_id}") |> map_size()

    streams_data =
      Enum.map(socket.assigns.streams_data, fn
        s when s.id == stream_id -> %{s | viewer_count: new_count}
        s -> s
      end)

    {:noreply, assign(socket, streams_data: streams_data)}
  end

  defp map_stream(s, count) do
    avatar_url =
      if s.user.profile_picture in [nil, ""],
        do: "https://ui-avatars.com/api/?name=#{s.user.username}&background=random",
        else: s.user.profile_picture

    %{
      id: s.id,
      stream_name: s.title,
      streamer: s.user.username,
      category: s.category || "Just Chatting",
      tags: s.tags || [],
      viewer_count: count,
      avatar: avatar_url,
      is_live: s.is_live,
      is_verified: s.user.is_verified,
      thumbnail_url: "/thumbnails/#{s.id}.jpg",
      hls_url: "/live/#{s.id}/index.m3u8"
    }
  end

  defp streams_to_cards(streams) do
    Enum.map(streams, fn s ->
      count = Presence.list("stream_viewers:#{s.id}") |> map_size()
      map_stream(s, count)
    end)
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Landing Page")}
  end
end
