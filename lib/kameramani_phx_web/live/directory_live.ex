defmodule KameramaniPhxWeb.DirectoryLive do
  alias KameramaniPhxWeb.CardComponents
  alias KameramaniPhx.Content
  alias KameramaniPhx.Streaming
  alias KameramaniPhxWeb.Presence
  use KameramaniPhxWeb, :live_view

  import CardComponents

  # def list_categories do
  #   [
  #     %{name: "Just Chatting", slug: "jt_cht", viewers: 7000},
  #     %{name: "Racing", slug: "rcng", viewers: 7000},
  #     %{name: "Gambling", slug: "lt_it_rde", viewers: 7000},
  #     %{name: "Strategy", slug: "strt", viewers: 7000}
  #   ]
  # end

  def fetch_categories do
    db_categories = list_db_categories()
    raw_games = KameramaniPhxWeb.Igdb.get_games()
    igdb_categories = format_igdb_games(raw_games)
    merge_categories(db_categories, igdb_categories)
  end

  def mount(params, _session, socket) do
    categories = fetch_categories()
    query = search_query_from_params(params)
    {categories, stream_results} = search_results_for_query(categories, query)
    active_tab = if query == "", do: "categories", else: "live"

    {:ok,
     socket
     |> assign(
       active_tab: active_tab,
       search_form: to_form(%{"query" => query}, as: :search),
       categories: categories,
       all_categories: categories,
       stream_results: stream_results
     )}
  end

  def handle_params(params, _uri, socket) do
    query = search_query_from_params(params)
    {categories, stream_results} = search_results_for_query(socket.assigns.all_categories, query)
    active_tab = if query == "", do: socket.assigns.active_tab, else: "live"

    {:noreply,
     socket
     |> assign(
       categories: categories,
       stream_results: stream_results,
       active_tab: active_tab,
       page_title: "Categories"
     )
     |> assign(search_form: to_form(%{"query" => query}, as: :search))}
  end

  def handle_event("search_directory", %{"search" => %{"query" => query}}, socket) do
    query = String.trim(query)
    {categories, stream_results} = search_results_for_query(socket.assigns.all_categories, query)

    {:noreply,
     socket
     |> assign(categories: categories, stream_results: stream_results)
     |> assign(search_form: to_form(%{"query" => query}, as: :search))}
  end

  def handle_event("set_directory_tab", %{"tab" => tab}, socket)
      when tab in ["categories", "live"] do
    socket =
      if tab == "live" do
        streams =
          if socket.assigns.search_form.params["query"] in [nil, ""] do
            Streaming.list_live_streams()
          else
            socket.assigns.stream_results
          end

        assign(socket, active_tab: tab, stream_results: streams_to_cards(streams))
      else
        assign(socket, active_tab: tab)
      end

    {:noreply, socket}
  end

  defp search_query_from_params(params) do
    cond do
      is_map(params["search"]) and is_binary(params["search"]["query"]) ->
        String.trim(params["search"]["query"])

      is_binary(params["query"]) ->
        String.trim(params["query"])

      true ->
        ""
    end
  end

  defp search_results_for_query(categories, query) do
    categories =
      if query == "" do
        categories
      else
        Enum.filter(categories, fn category ->
          String.contains?(String.downcase(category.name), String.downcase(query))
        end)
      end

    stream_results =
      if query == "" do
        []
      else
        query
        |> Streaming.list_live_streams_by_category_or_tag()
        |> streams_to_cards()
      end

    {categories, stream_results}
  end

  defp streams_to_cards(streams) do
    Enum.map(streams, fn s ->
      count = Presence.list("stream_viewers:#{s.id}") |> map_size()

      category_slug =
        if s.category do
          case Content.get_category_by_name(s.category) do
            %{slug: slug} -> slug
            _ -> slugify(s.category)
          end
        else
          # Default slug
          "just-chatting"
        end

      %{
        id: s.id,
        stream_name: s.title,
        streamer: s.user.username,
        category: s.category || "Just Chatting",
        category_slug: category_slug,
        tags: s.tags || [],
        viewer_count: count,
        avatar:
          if(s.user.profile_picture in [nil, ""],
            do: "https://ui-avatars.com/api/?name=#{s.user.username}&background=random",
            else: s.user.profile_picture
          ),
        is_live: s.is_live,
        is_verified: s.user.is_verified,
        thumbnail_url: "/thumbnails/#{s.id}.jpg"
      }
    end)
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

  defp list_db_categories do
    Content.list_categories()
    |> Enum.map(fn category ->
      %{
        name: category.name,
        slug: category.slug,
        thumbnail_url: category.thumbnail_url
      }
    end)
  end

  defp merge_categories(db_categories, igdb_categories) do
    db_by_slug = Map.new(db_categories, &{&1.slug, &1})

    igdb_only =
      igdb_categories
      |> Enum.reject(fn category -> Map.has_key?(db_by_slug, category.slug) end)

    db_categories ++ igdb_only
  end

  defp slugify(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
  end
end
