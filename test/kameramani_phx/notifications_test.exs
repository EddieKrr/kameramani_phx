defmodule KameramaniPhx.NotificationsTest do
  use KameramaniPhx.DataCase, async: true

  import KameramaniPhx.AccountsFixtures

  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Notifications
  alias KameramaniPhx.Streaming
  alias KameramaniPhx.Subscriptions

  test "following a user creates a follower notification" do
    follower = test_user_fixture("follower")
    followed = test_user_fixture("followed")

    Notifications.subscribe(followed.id)
    Accounts.follow_user(follower, followed)

    assert_receive :notifications_updated

    [notification] = Notifications.list_notifications(followed)
    assert notification.type == :new_follower
    assert notification.actor_id == follower.id
    assert Notifications.unread_count(followed) == 1
  end

  test "subscribing to a streamer creates a subscription notification" do
    subscriber = test_user_fixture("subscriber")
    streamer = test_user_fixture("streamer")

    Notifications.subscribe(streamer.id)

    assert {:ok, subscription} = Subscriptions.subscribe_to_streamer(subscriber.id, streamer.id, 3)
    assert_receive :notifications_updated

    [notification] = Notifications.list_notifications(streamer)
    assert notification.type == :new_subscription
    assert notification.actor_id == subscriber.id
    assert notification.entity_id == subscription.id
    assert notification.metadata["tier"] == 3
  end

  test "stream going live creates notifications for followers" do
    streamer = test_user_fixture("live-streamer")
    follower = test_user_fixture("live-follower")
    lurker = test_user_fixture("live-lurker")

    Accounts.follow_user(follower, streamer)

    {:ok, stream} =
      Streaming.create_stream(%{
        "user_id" => streamer.id,
        "is_live" => false,
        "title" => "Morning coding stream",
        "tags" => ["option1", "option2"]
      })

    Notifications.subscribe(follower.id)
    Notifications.subscribe(lurker.id)

    assert {:ok, _updated_stream} = Streaming.update_stream(stream, %{is_live: true})

    assert_receive :notifications_updated
    refute_receive :notifications_updated, 100

    [notification] = Notifications.list_notifications(follower)
    assert notification.type == :stream_went_live
    assert notification.actor_id == streamer.id
    assert notification.entity_id == stream.id
    assert notification.metadata["stream_title"] == "Morning coding stream"
    assert Notifications.list_notifications(lurker) == []
  end

  test "marking notifications as read updates unread count" do
    follower = test_user_fixture("read-follower")
    followed = test_user_fixture("read-followed")

    Accounts.follow_user(follower, followed)
    [notification] = Notifications.list_notifications(followed)

    assert Notifications.unread_count(followed) == 1

    :ok = Notifications.mark_as_read(followed, notification.id)

    assert Notifications.unread_count(followed) == 0
    [updated_notification] = Notifications.list_notifications(followed)
    assert %DateTime{} = updated_notification.read_at
  end

  test "marking all notifications as read clears all unread notifications" do
    follower_one = test_user_fixture("bulk-follower-one")
    follower_two = test_user_fixture("bulk-follower-two")
    followed = test_user_fixture("bulk-followed")

    Accounts.follow_user(follower_one, followed)
    Accounts.follow_user(follower_two, followed)

    assert Notifications.unread_count(followed) == 2

    :ok = Notifications.mark_all_as_read(followed)

    assert Notifications.unread_count(followed) == 0
    assert Enum.all?(Notifications.list_notifications(followed), &match?(%DateTime{}, &1.read_at))
  end

  defp test_user_fixture(prefix) do
    unconfirmed_user_fixture(%{
      name: "#{prefix} name",
      username: "#{prefix}-#{System.unique_integer([:positive])}",
      age: 30,
      password: "supersecret123"
    })
  end
end
