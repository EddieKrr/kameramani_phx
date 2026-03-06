defmodule KameramaniPhx.SubscriptionsTest do
  use KameramaniPhx.DataCase

  alias KameramaniPhx.Subscriptions

  describe "subscriptions" do
    alias KameramaniPhx.Subscriptions.Subscription

    import KameramaniPhx.AccountsFixtures
    import KameramaniPhx.SubscriptionsFixtures

    @invalid_attrs %{
      status: nil,
      tier: nil,
      amount_usd: nil,
      amount_kes: nil,
      fx_rate: nil,
      currency: nil,
      fx_fetched_at: nil,
      expires_at: nil
    }

    test "list_subscriptions/0 returns all subscriptions" do
      subscription = subscription_fixture()
      assert Subscriptions.list_subscriptions() == [subscription]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = subscription_fixture()
      assert Subscriptions.get_subscription!(subscription.id) == subscription
    end

    test "create_subscription/1 with valid data creates a subscription" do
      subscriber = user_fixture()
      streamer = user_fixture()

      valid_attrs = %{
        status: "active",
        tier: 3,
        amount_usd: Decimal.new("5.37"),
        amount_kes: Decimal.new("698.10"),
        fx_rate: Decimal.new("130.0"),
        currency: "KES",
        fx_fetched_at: ~U[2026-03-06 09:05:00Z],
        expires_at: ~U[2026-06-05 07:45:00Z],
        subscriber_id: subscriber.id,
        streamer_id: streamer.id
      }

      assert {:ok, %Subscription{} = subscription} = Subscriptions.create_subscription(valid_attrs)
      assert subscription.status == "active"
      assert subscription.tier == 3
      assert subscription.amount_usd == Decimal.new("5.37")
      assert subscription.amount_kes == Decimal.new("698.10")
      assert subscription.fx_rate == Decimal.new("130.0")
      assert subscription.currency == "KES"
      assert subscription.expires_at == ~U[2026-06-05 07:45:00Z]
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_subscription(@invalid_attrs)
    end

    test "update_subscription/2 with valid data updates the subscription" do
      subscription = subscription_fixture()

      update_attrs = %{
        status: "active",
        tier: 6,
        amount_usd: Decimal.new("10.15"),
        amount_kes: Decimal.new("1319.50"),
        fx_rate: Decimal.new("130.0"),
        currency: "KES",
        fx_fetched_at: ~U[2026-03-06 09:10:00Z],
        expires_at: ~U[2026-09-06 07:45:00Z]
      }

      assert {:ok, %Subscription{} = subscription} = Subscriptions.update_subscription(subscription, update_attrs)
      assert subscription.status == "active"
      assert subscription.tier == 6
      assert subscription.amount_usd == Decimal.new("10.15")
      assert subscription.amount_kes == Decimal.new("1319.50")
      assert subscription.fx_rate == Decimal.new("130.0")
      assert subscription.currency == "KES"
      assert subscription.expires_at == ~U[2026-09-06 07:45:00Z]
    end

    test "update_subscription/2 with invalid data returns error changeset" do
      subscription = subscription_fixture()
      assert {:error, %Ecto.Changeset{}} = Subscriptions.update_subscription(subscription, @invalid_attrs)
      assert subscription == Subscriptions.get_subscription!(subscription.id)
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = subscription_fixture()
      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_subscription!(subscription.id) end
    end

    test "change_subscription/1 returns a subscription changeset" do
      subscription = subscription_fixture()
      assert %Ecto.Changeset{} = Subscriptions.change_subscription(subscription)
    end
  end
end
