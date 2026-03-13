defmodule KameramaniPhx.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false

  alias KameramaniPhx.Accounts.{Follow, Scope, User, UserNotifier}
  alias KameramaniPhx.Notifications.Notification
  alias KameramaniPhx.Repo
  alias KameramaniPhx.Streaming.Stream
  alias KameramaniPhx.Subscriptions.Subscription

  def subscribe(recipient_id) when is_binary(recipient_id) do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, topic(recipient_id))
  end

  def list_notifications(current_user, opts \\ []) do
    recipient_id = recipient_id_for(current_user)
    limit = Keyword.get(opts, :limit, 10)

    from(n in Notification,
      where: n.recipient_id == ^recipient_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  def unread_count(current_user) do
    recipient_id = recipient_id_for(current_user)

    from(n in Notification,
      where: n.recipient_id == ^recipient_id and is_nil(n.read_at)
    )
    |> Repo.aggregate(:count)
  end

  def mark_as_read(current_user, notification_id) when is_binary(notification_id) do
    recipient_id = recipient_id_for(current_user)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
      from(n in Notification,
        where: n.id == ^notification_id and n.recipient_id == ^recipient_id and is_nil(n.read_at)
      )
      |> Repo.update_all(set: [read_at: now])

    if count > 0, do: broadcast_refresh(recipient_id)
    :ok
  end

  def mark_all_as_read(current_user) do
    recipient_id = recipient_id_for(current_user)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
      from(n in Notification,
        where: n.recipient_id == ^recipient_id and is_nil(n.read_at)
      )
      |> Repo.update_all(set: [read_at: now])

    if count > 0, do: broadcast_refresh(recipient_id)
    :ok
  end

  def notify_new_follower(%User{} = follower, %User{} = followed_user) do
    create_notification(%{
      recipient_id: followed_user.id,
      actor_id: follower.id,
      type: :new_follower,
      entity_type: "user",
      entity_id: follower.id,
      metadata: %{
        "actor_username" => follower.username
      }
    })
  end

  def notify_new_subscription(%User{} = subscriber, %User{} = streamer, %Subscription{} = subscription) do
    create_notification(%{
      recipient_id: streamer.id,
      actor_id: subscriber.id,
      type: :new_subscription,
      entity_type: "subscription",
      entity_id: subscription.id,
      metadata: %{
        "actor_username" => subscriber.username,
        "tier" => subscription.tier
      }
    })
  end

  def notify_stream_went_live(%User{} = streamer, %Stream{} = stream) do
    follower_ids =
      from(f in Follow,
        where: f.followed_id == ^streamer.id,
        select: f.follower_id
      )
      |> Repo.all()

    if follower_ids == [] do
      :ok
    else
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entries =
        Enum.map(follower_ids, fn follower_id ->
          %{
            id: Ecto.UUID.generate(),
            recipient_id: follower_id,
            actor_id: streamer.id,
            type: :stream_went_live,
            entity_type: "stream",
            entity_id: stream.id,
            metadata: %{
              "actor_username" => streamer.username,
              "stream_title" => stream.title
            },
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.insert_all(Notification, entries)
      Enum.each(follower_ids, &broadcast_refresh/1)
      :ok
    end
  end


  #clearing notifications
  def clear_notifications(current_user) do
    recipient_id = recipient_id_for(current_user)

    from(n in Notification,
      where: n.recipient_id == ^recipient_id
    )
    |> Repo.delete_all()

    broadcast_refresh(recipient_id)
    :ok
  end

  
  def notify_verification_submitted(%User{} = user, verification_id) do
    # Get all admins/mods to notify them
    admin_ids =
      from(u in User,
        join: r in assoc(u, :roles),
        where: r.name in ["admin", "moderator"],
        select: u.id
      )
      |> Repo.all()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(admin_ids, fn admin_id ->
        %{
          id: Ecto.UUID.generate(),
          recipient_id: admin_id,
          actor_id: user.id,
          type: :verification_submitted,
          entity_type: "verification_request",
          entity_id: to_string(verification_id),
          metadata: %{
            "actor_username" => user.username
          },
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(Notification, entries)
    Enum.each(admin_ids, &broadcast_refresh/1)

    # Send email to the user
    UserNotifier.deliver_verification_submitted(user)

    # Also broadcast specifically for the admin panel real-time list
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "admin:verifications", :verification_request_submitted)
    :ok
  end

  def notify_verification_approved(%User{} = user, verification_id) do
    UserNotifier.deliver_verification_approved(user)

    case create_notification(%{
           recipient_id: user.id,
           type: :verification_approved,
           entity_type: "verification_request",
           entity_id: to_string(verification_id),
           metadata: %{
             "message" => "Congratulations! Your account has been verified.",
             "actor_username" => user.username
           }
         }) do
      {:ok, notification} ->
        broadcast_verification_status(user.id, :approved)
        {:ok, notification}

      error ->
        error
    end
  end

  def notify_verification_rejected(%User{} = user, verification_id) do
    UserNotifier.deliver_verification_rejected(user)

    case create_notification(%{
           recipient_id: user.id,
           type: :verification_rejected,
           entity_type: "verification_request",
           entity_id: to_string(verification_id),
           metadata: %{
             "message" => "Your verification request was not approved at this time.",
             "actor_username" => user.username
           }
         }) do
      {:ok, notification} ->
        broadcast_verification_status(user.id, :rejected)
        {:ok, notification}

      error ->
        error
    end
  end

  defp create_notification(attrs) do
    case %Notification{}
         |> Notification.changeset(attrs)
         |> Repo.insert() do
      {:ok, notification} ->
        notification = Repo.preload(notification, :actor)
        broadcast_refresh(notification.recipient_id)
        {:ok, notification}

      error ->
        error
    end
  end

  defp recipient_id_for(%Scope{user: %User{id: user_id}}), do: user_id
  defp recipient_id_for(%User{id: user_id}), do: user_id
  defp recipient_id_for(user_id) when is_binary(user_id), do: user_id

  defp broadcast_refresh(recipient_id) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, topic(recipient_id), :notifications_updated)
  end

  defp broadcast_verification_status(recipient_id, status) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, verification_topic(recipient_id), {:verification_status_updated, status})
  end

  def verification_topic(recipient_id),
    do: "verifications:user:#{recipient_id}"

  defp topic(recipient_id), do: "notifications:user:#{recipient_id}"
end
