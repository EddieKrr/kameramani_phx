defmodule KameramaniPhxWeb.Igdb do
  require Logger

  @games_endpoint "https://api.igdb.com/v4/games"

  def get_games() do
    response =
      Req.post!(
        @games_endpoint,
        headers: %{
          "Client-ID" => "nu17d3exzkq4saqurg8xz2779hcono",
          "Authorization" => "Bearer peemvccqyj5kv8yge7zmss5gczwtm1"
        },
        body: "fields name, cover.url; limit 100;"
      )

    response.body
  end
end

  # defp request_games(headers) do
  #   Req.post(
  #     @games_endpoint,
  #     headers: headers,
  #     body: "fields name, cover.url; limit 100;"
  #   )
  #   |> case do
  #     {:ok, response} ->
  #       case response.status do
  #         status when status in 200..299 ->
  #           if is_list(response.body) do
  #             response.body
  #           else
  #             Logger.warning(
  #               "IGDB request succeeded but returned unexpected body: #{inspect(response.body)}"
  #             )

  #             fallback_games()
  #           end

  #         status ->
  #           Logger.warning(
  #             "IGDB request failed with status #{status}: #{inspect(response.body)}"
  #           )

  #           fallback_games()
  #       end

  #     {:error, %Req.TransportError{} = error} ->
  #       Logger.warning("IGDB request failed: #{Exception.message(error)}")
  #       fallback_games()

  #     {:error, error} ->
  #       Logger.warning("IGDB request failed: #{inspect(error)}")
  #       fallback_games()
  #   end
  # end

  # defp build_headers do
  #   client_id = System.get_env("IGDB_CLIENT_ID")
  #   access_token = System.get_env("IGDB_ACCESS_TOKEN")

  #   cond do
  #     client_id in [nil, ""] -> {:error, "missing IGDB_CLIENT_ID"}
  #     access_token in [nil, ""] -> {:error, "missing IGDB_ACCESS_TOKEN"}
  #     true -> {:ok, %{"Client-ID" => client_id, "Authorization" => "Bearer #{access_token}"}}
  #   end
  # end

  # defp fallback_games do
  #   [
  #     %{"name" => "Just Chatting", "cover" => %{"url" => nil}},
  #     %{"name" => "Gaming", "cover" => %{"url" => nil}},
  #     %{"name" => "Music", "cover" => %{"url" => nil}},
  #     %{"name" => "Sports", "cover" => %{"url" => nil}},
  #     %{"name" => "Art", "cover" => %{"url" => nil}},
  #     %{"name" => "IRL", "cover" => %{"url" => nil}},
  #     %{"name" => "Education", "cover" => %{"url" => nil}},
  #     %{"name" => "Technology", "cover" => %{"url" => nil}},
  #     %{"name" => "Fitness", "cover" => %{"url" => nil}},
  #     %{"name" => "Travel", "cover" => %{"url" => nil}}
  #   ]
  # end
