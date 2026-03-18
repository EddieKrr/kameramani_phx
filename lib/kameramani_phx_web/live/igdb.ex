defmodule KameramaniPhxWeb.Igdb do
  def get_games() do
    response =
      Req.post!("https://api.igdb.com/v4/games",
        headers: %{
          "Client-ID" => "nu17d3exzkq4saqurg8xz2779hcono",
          "Authorization" => "Bearer peemvccqyj5kv8yge7zmss5gczwtm1"
        },
        body: "fields name, cover.url; limit 100;"
      )

    response.body
  end
end
