defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use KameramaniPhxWeb, :live_view
  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Accounts.Scope
  alias KameramaniPhx.Subscriptions
  alias KameramaniPhx.Notifications
  import KameramaniPhxWeb.ProfileComponents
  import Ecto.Query
  alias KameramaniPhx.Repo
  alias KameramaniPhx.Socials
  alias KameramaniPhx.Streaming

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:all")

      case socket.assigns[:current_user] do
        %{user: %{id: user_id}} ->
          Phoenix.PubSub.subscribe(
            KameramaniPhx.PubSub,
            Notifications.verification_topic(user_id)
          )

        _ ->
          :ok
      end
    end

    {:ok,
     assign(socket,
       user: nil,
       is_live: false,
       stream_id: nil,
       active_stream: nil,
       follower_count: 0,
       following_count: 0,
       subscriber_count: 0,
       is_following: false,
       is_subscribed: false,
       show_subscribe_modal: false,
       selected_tier: 1,
       tier_options: Subscriptions.tier_options(),
       show_verification_modal: false,
       verification_request: nil,
       social_platforms: [
         %{id: "youtube", name: "YouTube", icon: "youtube", prefix: "https://youtube.com/@"},
         %{
           id: "instagram",
           name: "Instagram",
           icon: "instagram",
           prefix: "https://instagram.com/"
         },
         %{id: "x", name: "X", icon: "x-brand", prefix: "https://x.com/"},
         %{id: "twitch", name: "Twitch", icon: "twitch", prefix: "https://twitch.tv/"},
         %{id: "tiktok", name: "TikTok", icon: "tiktok", prefix: "https://tiktok.com/@"},
         %{id: "discord", name: "Discord", icon: "discord", prefix: "https://discord.com/users/"}
       ],
       selected_platform: "youtube",
       social_username: ""
     )}
  end

  def handle_params(%{"username" => username} = params, _uri, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:noreply, push_navigate(socket, to: ~p"/directory")}

      user ->
        avatar_url =
          if user.profile_picture in [nil, ""],
            do: "https://ui-avatars.com/api/?name=#{user.username}&background=random&size=150",
            else: user.profile_picture

        time =
          if user.inserted_at,
            do: "#{DateTime.diff(DateTime.utc_now(), user.inserted_at, :day)} days",
            else: "N/A"

        social_accounts = Socials.list_user_socials(user)

        current_user_data =
          case socket.assigns[:current_user] do
            %{user: u} -> u
            _ -> nil
          end

        verification_request =
          if current_user_data && current_user_data.id == user.id do
            Accounts.get_latest_verification_request(current_user_data)
          else
            nil
          end

        is_following =
          if current_user_data do
            Accounts.is_following?(current_user_data, user)
          else
            false
          end

        is_subscribed =
          if current_user_data do
            Subscriptions.subscribed_to_streamer?(current_user_data.id, user.id)
          else
            false
          end

        # Check if user is live
        active_stream = Streaming.get_active_stream_for_user(user.id)

        tab = Map.get(params, "tab", "home")

        vods = list_vods(user.id)

        socket =
          socket
          |> assign(user: user)
          |> assign(social_accounts: social_accounts)
          |> assign(vods: vods)
          |> assign(avatar_url: avatar_url)
          |> assign(time: time)
          |> assign(active_tab: tab)
          |> assign(is_following: is_following)
          |> assign(is_subscribed: is_subscribed)
          |> assign(follower_count: Accounts.get_followers_count(user))
          |> assign(following_count: Accounts.get_following_count(user))
          |> assign(subscriber_count: Subscriptions.subscriber_count(user.id))
          |> assign(show_subscribe_modal: false)
          |> assign(selected_tier: 1)
          |> assign(tier_options: Subscriptions.tier_options())
          |> assign(is_live: !!active_stream)
          |> assign(stream_id: if(active_stream, do: active_stream.id, else: nil))
          |> assign(active_stream: active_stream)
          |> assign(verification_request: verification_request)
          |> assign(page_title: "Profile")

        {:noreply, socket}
    end
  end

  def handle_info({:stream_status_updated, stream}, socket) do
    profile_user = socket.assigns[:user]

    if profile_user && profile_user.id == stream.user_id do
      active_stream =
        if stream.is_live do
          stream
        else
          nil
        end

      {:noreply,
       socket
       |> assign(is_live: stream.is_live)
       |> assign(stream_id: if(active_stream, do: active_stream.id, else: nil))
       |> assign(active_stream: active_stream)
       |> assign(vods: list_vods(profile_user.id))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:verification_status_updated, status}, socket) do
    scope = socket.assigns[:current_user]
    current_user = scope && scope.user
    profile_user = socket.assigns[:user]

    cond do
      is_nil(current_user) or is_nil(profile_user) or current_user.id != profile_user.id ->
        {:noreply, socket}

      true ->
        updated_user = Accounts.get_user!(profile_user.id)
        verification_request = Accounts.get_latest_verification_request(updated_user)
        updated_scope = Scope.for_user(updated_user)

        socket =
          socket
          |> assign(user: updated_user)
          |> assign(verification_request: verification_request)
          |> assign(current_user: updated_scope)

        socket =
          case verification_flash(status) do
            {kind, message} -> put_flash(socket, kind, message)
            nil -> socket
          end

        {:noreply, socket}
    end
  end

  def handle_event("set_active_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("toggle_follow", _params, socket) do
    current_user = if socket.assigns.current_user, do: socket.assigns.current_user.user, else: nil
    profile_user = socket.assigns.user

    if current_user do
      if current_user.id == profile_user.id do
        {:noreply, put_flash(socket, :error, "You cannot follow yourself")}
      else
        if socket.assigns.is_following do
          Accounts.unfollow_user(current_user, profile_user)

          {:noreply,
           socket
           |> assign(is_following: false)
           |> assign(follower_count: max(socket.assigns.follower_count - 1, 0))}
        else
          Accounts.follow_user(current_user, profile_user)

          {:noreply,
           socket
           |> assign(is_following: true)
           |> assign(follower_count: socket.assigns.follower_count + 1)}
        end
      end
    else
      {:noreply,
       socket
       |> put_flash(:info, "Please log in to follow")
       |> push_navigate(to: ~p"/auth")}
    end
  end

  def handle_event("open_subscribe_modal", _params, socket) do
    current_user = if socket.assigns.current_user, do: socket.assigns.current_user.user, else: nil
    profile_user = socket.assigns.user

    cond do
      is_nil(current_user) ->
        {:noreply,
         socket
         |> put_flash(:info, "Please log in to subscribe")
         |> push_navigate(to: ~p"/auth")}

      current_user.id == profile_user.id ->
        {:noreply, put_flash(socket, :error, "You cannot subscribe to yourself")}

      true ->
        {:noreply, assign(socket, show_subscribe_modal: true)}
    end
  end

  def handle_event("close_subscribe_modal", _params, socket) do
    {:noreply, assign(socket, show_subscribe_modal: false)}
  end

  def handle_event("select_tier", %{"tier" => tier}, socket) do
    case Integer.parse(tier) do
      {tier_int, ""} when tier_int in [1, 3, 6] ->
        {:noreply, assign(socket, selected_tier: tier_int)}

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid subscription tier")}
    end
  end

  def handle_event("subscribe_to_tier", _params, socket) do
    current_user = if socket.assigns.current_user, do: socket.assigns.current_user.user, else: nil
    profile_user = socket.assigns.user

    if current_user do
      was_subscribed = socket.assigns.is_subscribed

      case Subscriptions.subscribe_to_streamer(
             current_user.id,
             profile_user.id,
             socket.assigns.selected_tier
           ) do
        {:ok, _subscription} ->
          subscriber_count =
            if was_subscribed do
              socket.assigns.subscriber_count
            else
              socket.assigns.subscriber_count + 1
            end

          {:noreply,
           socket
           |> assign(is_subscribed: true)
           |> assign(subscriber_count: subscriber_count)
           |> assign(show_subscribe_modal: false)
           |> put_flash(:info, "Subscription updated")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Could not subscribe right now")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please log in to subscribe")}
    end
  end

  def handle_event("open_verification_modal", _params, socket) do
    {:noreply, assign(socket, show_verification_modal: true)}
  end

  def handle_event("close_verification_modal", _params, socket) do
    {:noreply, assign(socket, show_verification_modal: false)}
  end

  def handle_event("select_platform", %{"platform" => platform}, socket) do
    {:noreply, assign(socket, selected_platform: platform)}
  end

  def handle_event("update_social_username", %{"username" => username}, socket) do
    {:noreply, assign(socket, social_username: username)}
  end

  def handle_event("update_social_username", %{"value" => value}, socket) do
    {:noreply, assign(socket, social_username: value)}
  end

  def handle_event("add_social_account", _params, socket) do
    current_user = socket.assigns.current_user.user
    platform_id = socket.assigns.selected_platform
    username = socket.assigns.social_username

    if username == "" do
      {:noreply, put_flash(socket, :error, "Username cannot be empty")}
    else
      platform = Enum.find(socket.assigns.social_platforms, &(&1.id == platform_id))
      url = platform.prefix <> username

      attrs = %{
        platform: platform_id,
        username: username,
        url: url,
        user_id: current_user.id
      }

      case Socials.add_social_account(current_user, attrs) do
        {:ok, _social} ->
          social_accounts = Socials.list_user_socials(socket.assigns.user)

          {:noreply,
           socket
           |> assign(social_accounts: social_accounts)
           |> assign(social_username: "")
           |> put_flash(:info, "Social account added")}

        {:error, changeset} ->
          error_msg =
            case changeset.errors[:user_id] do
              {msg, _} -> "Error: #{msg}"
              _ -> "Could not add social account"
            end

          {:noreply, put_flash(socket, :error, error_msg)}
      end
    end
  end

  def handle_event("remove_social_account", %{"id" => id}, socket) do
    social = Socials.get_social_account!(id)

    case Socials.delete_social_account(social) do
      {:ok, _} ->
        social_accounts = Socials.list_user_socials(socket.assigns.user)
        {:noreply, assign(socket, social_accounts: social_accounts)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not remove social account")}
    end
  end

  # user wants to get verified
  def handle_event("request_verification", _params, socket) do
    current_user = if socket.assigns.current_user, do: socket.assigns.current_user.user, else: nil

    cond do
      is_nil(current_user) ->
        {:noreply,
         socket
         |> put_flash(:info, "Please log in to request verification")
         |> push_navigate(to: ~p"/auth")}

      current_user.is_verified == true ->
        {:noreply, put_flash(socket, :error, "You are already a verified user")}

      Accounts.check_verification_status(current_user) ->
        {:noreply, put_flash(socket, :error, "You already have a pending verification request")}

      Enum.empty?(socket.assigns.social_accounts) ->
        {:noreply, put_flash(socket, :error, "Please add at least one social account first")}

      true ->
        case Accounts.get_verified(current_user) do
          {:ok, request} ->
            {:noreply,
             socket
             |> assign(verification_request: request)
             |> assign(show_verification_modal: false)
             |> put_flash(:info, "Verification request submitted")}

          {:error, :already_requested} ->
            {:noreply, put_flash(socket, :error, "Verification already requested")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Could not submit verification request")}
        end
    end
  end

  defp verification_flash(:approved), do: {:info, "Verification approved! You're now verified."}

  defp verification_flash(:rejected),
    do: {:error, "Verification request rejected. Please check your inbox for details."}

  defp verification_flash(_), do: nil

  defp list_vods(user_id) do
    query =
      from(v in KameramaniPhx.Streaming.Stream,
        where: v.user_id == ^user_id and v.is_live == false,
        preload: [:user]
      )

    Repo.all(query)
  end
end
