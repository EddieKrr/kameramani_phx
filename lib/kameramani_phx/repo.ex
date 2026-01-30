defmodule KameramaniPhx.Repo do
  use Ecto.Repo,
    otp_app: :kameramani_phx,
    adapter: Ecto.Adapters.Postgres
end
