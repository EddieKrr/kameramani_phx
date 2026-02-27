defmodule KameramaniPhxWeb.ChatLive do
  use KameramaniPhxWeb, :live_view
  import Ecto.Query
  import KameramaniPhxWeb.SidebarComponents

  alias KameramaniPhx.Accounts

  alias KameramaniPhx.Accounts.Scope
  alias KameramaniPhxWeb.Presence
  # Keep your mount user
  # on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user} # Removed


  defp subscribe(stream_id) do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "stream_state:#{stream_id}")
  end

  def mount(%{"username" => username}, session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/")}

      user ->
        # Fetch the stream for this user (even if offline)
        case KameramaniPhx.Streaming.get_stream_for_user(user.id) do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "This user hasn't set up a channel yet")
             |> push_navigate(to: ~p"/")}

          stream ->
            # Setup Presence and PubSub topics
            topic = "stream_viewers:#{stream.id}"
            user_id = session["live_socket_id"] || session["guest_id"] || socket.id

            if connected?(socket) do
              KameramaniPhxWeb.Endpoint.subscribe(topic)

              # Track this user in Presence using a stable ID from session
              Presence.track(self(), topic, user_id, %{
                joined_at: System.system_time(:second)
              })

              # Subscribe to the chat and stream state PubSub topics
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
              left_sidebar_open: true,
              chat_open: true,
              stream_started_at: stream.updated_at || DateTime.utc_now(),
              recommended_streams: recommended_streams
            }

            {:ok,
             socket
             |> assign(current_user: current_user_scope)
             |> assign(assigns_to_socket)}
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
          {:noreply, assign(socket, is_following: false)}
        else
          Accounts.follow_user(current_user, streamer_id)
          {:noreply, assign(socket, is_following: true)}
        end
      end
    else
      {:noreply,
       socket
       |> put_flash(:info, "Please log in to follow")
       |> push_navigate(to: ~p"/auth")}
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

  # handling the viewer count updates via Presence
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    topic = "stream_viewers:#{socket.assigns.stream_id}"
    new_count = Presence.list(topic) |> map_size()
    {:noreply, assign(socket, viewer_count: new_count)}
  end
end

