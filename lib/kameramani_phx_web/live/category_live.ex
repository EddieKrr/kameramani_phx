defmodule KameramaniPhxWeb.CategoryLive do
  alias KameramaniPhx.Content
  alias KameramaniPhx.Streaming
  alias KameramaniPhxWeb.CardComponents
  alias KameramaniPhxWeb.Igdb
  alias KameramaniPhxWeb.Presence
  use KameramaniPhxWeb, :live_view

  import CardComponents

  def mount(_params, _session, socket) do
    {:ok, assign(socket, category: nil, category_slug: nil, stream_results: [])}
  end

  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Content.get_category_by_slug(slug) do
      nil ->
        case get_igdb_category_by_slug(slug) do
          nil ->
            fallback_name = slug_to_name(slug)
            streams = Streaming.get_streams_by_category(fallback_name)

            {:noreply,
             assign(socket,
               category: %{name: fallback_name, slug: slug, thumbnail_url: nil},
               category_slug: slug,
               stream_results: streams_to_cards(streams)
             )}

          igdb_category ->
            streams = Streaming.get_streams_by_category(igdb_category.name)

            {:noreply,
             assign(socket,
               category: igdb_category,
               category_slug: slug,
               stream_results: streams_to_cards(streams)
             )}
        end

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

  defp get_igdb_category_by_slug(slug) when is_binary(slug) do
    Igdb.get_games()
    |> format_igdb_games()
    |> Enum.find(fn category -> category.slug == slug end)
  end

  defp format_igdb_games(raw_games) when is_list(raw_games) do
    raw_games
    |> Enum.filter(&is_map/1)
    |> Enum.filter(fn game -> is_binary(game["name"]) and game["name"] != "" end)
    |> Enum.map(fn game ->
      cover_url =
        if is_map(game["cover"]) and is_binary(game["cover"]["url"]) do
          "https:#{game["cover"]["url"]}" |> String.replace("t_thumb", "t_cover_big")
        else
          "https://placehold.co/400x533/4c1d95/ffffff?text=No+Cover"
        end

      %{
        name: game["name"],
        slug: slugify(game["name"]),
        thumbnail_url: cover_url
      }
    end)
  end

  defp format_igdb_games(_), do: []

  defp slugify(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\\s-]/u, "")
    |> String.replace(~r/\\s+/, "-")
  end

  defp slug_to_name(slug) when is_binary(slug) do
    slug
    |> String.trim()
    |> String.replace("-", " ")
    |> String.replace(~r/\\s+/, " ")
    |> String.split(" ", trim: true)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
