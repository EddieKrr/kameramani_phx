defmodule Presence do
  use Phoenix.Presence,
    otp_app: :kameramani_phx,
    pubsub_server: KameramaniPhx.PubSub
end
