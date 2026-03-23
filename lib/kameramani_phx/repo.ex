defmodule KameramaniPhx.Repo do
  use Ecto.Repo,
    otp_app: :kameramani_phx,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
