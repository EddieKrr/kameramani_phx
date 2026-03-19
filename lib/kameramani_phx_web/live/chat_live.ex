defmodule KameramaniPhxWeb.ChatLive do
  use KameramaniPhxWeb, :live_view
  import Ecto.Query
  import KameramaniPhxWeb.SidebarComponents

  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Subscriptions
  alias KameramaniPhx.Streaming

  alias KameramaniPhx.Accounts.Scope
  alias KameramaniPhxWeb.Presence


  defp subscribe(stream_id) do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "stream_state:#{stream_id}")
  end

  @per_ip_limit 3
  @total_viewer_limit 1000

  def mount(%{"username" => username}, session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/")}

      user ->
        stream = Streaming.get_stream_for_user(user.id)

        case stream do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "This user hasn't set up a stream yet")
             |> push_navigate(to: ~p"/")}

          %Streaming.Stream{} = stream ->
            client_ip = live_ip(socket)
            topic = "stream_viewers:#{stream.id}"
            user_id = session["live_socket_id"] || session["guest_id"] || socket.id

            cond do
              total_viewer_limit_reached?(stream.id) ->
                {:ok,
                 socket
                 |> put_flash(:error, "This stream has reached its viewer capacity right now.")
                 |> push_navigate(to: ~p"/")}

              per_ip_limit_reached?(stream.id, client_ip) ->
                {:ok,
                 socket
                 |> put_flash(:error, "Too many connections from your IP. Please try again later.")
                 |> push_navigate(to: ~p"/")}

              true ->
                if connected?(socket) do
                  KameramaniPhxWeb.Endpoint.subscribe(topic)
                  Presence.track(self(), topic, user_id, %{
                    joined_at: System.system_time(:second),
                    ip: client_ip
                  })
                  subscribe(stream.id)
                end

                # Get the initial viewer count
                initial_count = Presence.list(topic) |> map_size()

                # Use current_user from the live_session mount, allow guests to view
                current_user_scope = socket.assigns.current_user || %Scope{user: nil}
                current_user = current_user_scope.user

                # Check if current user is following this streamer
                is_following =
                  if current_user, do: Accounts.is_following?(current_user, user), else: false

                is_subscribed =
                  if current_user do
                    Subscriptions.subscribed_to_streamer?(current_user.id, user.id)
                  else
                    false
                  end

                # Fetch recommended streamers for the sidebar (similar to LandingLive)
                recommended_streams =
                  KameramaniPhx.Repo.all(
                    from s in KameramaniPhx.Streaming.Stream,
                      where: s.is_live == true,
                      limit: 10,
                      preload: [:user]
                  )
                  |> Enum.map(fn s ->
                    count = Presence.list("stream_viewers:#{s.id}") |> map_size()

                    %{
                      name: s.user.username,
                      game: s.category || "Just Chatting",
                      viewer_count: count,
                      src:
                        if(s.user.profile_picture in [nil, ""],
                          do: "https://ui-avatars.com/api/?name=#{s.user.username}&background=random",
                          else: s.user.profile_picture
                        )
                    }
                  end)

                avatar_url =
                  if user.profile_picture in [nil, ""],
                    do: "https://ui-avatars.com/api/?name=#{user.username}&background=random",
                    else: user.profile_picture

                # Assign all the data to the socket
                assigns_to_socket = %{
                  stream_id: stream.id,
                  streamer_id: user.id,
                  viewer_count: initial_count,
                  streamer_name: user.username,
                  streamer_profile_picture: avatar_url,
                  category_name: stream.category || "Just Chatting",
                  stream_name: stream.title,
                  tags: stream.tags || [],
                  is_live: stream.is_live,
                  is_following: is_following,
                  is_subscribed: is_subscribed,
                  follower_count: Accounts.get_followers_count(user),
                  subscriber_count: Subscriptions.subscriber_count(user.id),
                  show_subscribe_modal: false,
                  selected_tier: 1,
                  tier_options: Subscriptions.tier_options(),
                  left_sidebar_open: true,
                  chat_open: true,
                  stream_started_at: stream.updated_at || DateTime.utc_now(),
                  recommended_streams: recommended_streams,
                  page_title: "#{user.username}'s Stream"
                }

                {:ok,
                 socket
                 |> assign(current_user: current_user_scope)
                 |> assign(assigns_to_socket)}
            end
        end
    end
  end

  # toggle sidebars
  def handle_event("toggle_left_sidebar", _, socket) do
    {:noreply, assign(socket, left_sidebar_open: !socket.assigns.left_sidebar_open)}
  end

  def handle_event("toggle_chat", _, socket) do
    {:noreply, assign(socket, chat_open: !socket.assigns.chat_open)}
  end

  def handle_event("toggle_follow", _params, socket) do
    current_user =
      if socket.assigns.current_user, do: socket.assigns.current_user.user, else: nil

    streamer_id = socket.assigns.streamer_id

    if current_user do
      if current_user.id == streamer_id do
        {:noreply, put_flash(socket, :error, "You cannot follow yourself")}
      else
        if socket.assigns.is_following do
          Accounts.unfollow_user(current_user, streamer_id)

          {:noreply,
           socket
           |> assign(is_following: false)
           |> assign(follower_count: max(socket.assigns.follower_count - 1, 0))}
        else
          Accounts.follow_user(current_user, streamer_id)

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
    current_user =
      if socket.assigns.current_user, do: socket.assigns.current_user.user, else: nil

    streamer_id = socket.assigns.streamer_id

    cond do
      is_nil(current_user) ->
        {:noreply,
         socket
         |> put_flash(:info, "Please log in to subscribe")
         |> push_navigate(to: ~p"/auth")}

      current_user.id == streamer_id ->
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
    current_user =
      if socket.assigns.current_user, do: socket.assigns.current_user.user, else: nil

    if current_user do
      streamer_id = socket.assigns.streamer_id
      tier = socket.assigns.selected_tier
      was_subscribed = socket.assigns.is_subscribed

      case Subscriptions.subscribe_to_streamer(current_user.id, streamer_id, tier) do
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

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: socket.assigns.streamer_name <> " | Chat")}
  end

  def handle_info({:stream_status, status}, socket) do
    is_live = status == :online
    {:noreply, assign(socket, is_live: is_live)}
  end

  def handle_info({:new_message, message}, socket) do
    send_update(KameramaniPhxWeb.ChatLiveComponent,
      id: "chat-component",
      stream_id: socket.assigns.stream_id,
      new_message: message
    )
    {:noreply, socket}
  end

  # handling the viewer count updates via Presence
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    topic = "stream_viewers:#{socket.assigns.stream_id}"
    new_count = Presence.list(topic) |> map_size()
    {:noreply, assign(socket, viewer_count: new_count)}
  end

  defp total_viewer_limit_reached?(stream_id) do
    topic = "stream_viewers:#{stream_id}"

    Presence.list(topic)
    |> map_size()
    |> Kernel.>=(@total_viewer_limit)
  end

  defp per_ip_limit_reached?(_stream_id, nil), do: false

  defp per_ip_limit_reached?(stream_id, client_ip) do
    topic = "stream_viewers:#{stream_id}"

    Presence.list(topic)
    |> Enum.count(fn {_id, meta} -> Map.get(meta, :ip) == client_ip end)
    |> Kernel.>=(@per_ip_limit)
  end

  defp live_ip(socket) do
    socket
    |> Map.get(:connect_info, %{})
    |> Map.get(:peer_data, %{})
    |> Map.get(:address)
    |> case do
      nil -> nil
      address -> :inet_parse.ntoa(address) |> to_string()
    end
  end
end
