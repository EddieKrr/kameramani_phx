defmodule KameramaniPhxWeb.CategoryLive do
  alias KameramaniPhx.Content
  alias KameramaniPhx.Streaming
  alias KameramaniPhxWeb.CardComponents
  alias KameramaniPhxWeb.Presence
  use KameramaniPhxWeb, :live_view

  import CardComponents

  def mount(_params, _session, socket) do
    {:ok, assign(socket, category: nil, category_slug: nil, stream_results: [])}
  end

  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Content.get_category_by_slug(slug) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Category not found")
         |> push_navigate(to: ~p"/directory")}

      category ->
        streams = Streaming.get_streams_by_category(category.name)

        {:noreply,
         assign(socket,
           category: category,
           category_slug: slug,
           stream_results: streams_to_cards(streams)
         )}
    end
  end

  defp streams_to_cards(streams) do
    Enum.map(streams, fn stream ->
      count = Presence.list("stream_viewers:#{stream.id}") |> map_size()

      %{
        id: stream.id,
        stream_name: stream.title,
        streamer: stream.user.username,
        category: stream.category || "Just Chatting",
        tags: stream.tags || [],
        viewer_count: count,
        avatar:
          if(stream.user.profile_picture in [nil, ""],
            do: "https://ui-avatars.com/api/?name=#{stream.user.username}&background=random",
            else: stream.user.profile_picture
          ),
        is_live: stream.is_live,
        is_verified: stream.user.is_verified,
        thumbnail_url: "/thumbnails/#{stream.id}.jpg"
      }
    end)
  end
end
