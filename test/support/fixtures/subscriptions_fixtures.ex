defmodule KameramaniPhx.SubscriptionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Subscriptions` context.
  """

  alias KameramaniPhx.AccountsFixtures

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(attrs \\ %{}) do
    subscriber = AccountsFixtures.user_fixture()
    streamer = AccountsFixtures.user_fixture()

    {:ok, subscription} =
      attrs
      |> Enum.into(%{
        amount_usd: Decimal.new("1.99"),
        amount_kes: Decimal.new("258.70"),
        fx_rate: Decimal.new("130.0"),
        currency: "KES",
        fx_fetched_at: ~U[2026-03-06 09:05:00Z],
        expires_at: ~U[2026-04-05 07:45:00Z],
        status: "active",
        tier: 1,
        subscriber_id: subscriber.id,
        streamer_id: streamer.id
      })
      |> KameramaniPhx.Subscriptions.create_subscription()

    subscription
  end
end
