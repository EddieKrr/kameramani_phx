defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use KameramaniPhxWeb, :live_view
  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Streaming

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}

  def mount(%{"username" => username}, _session, socket) do
    # Fetch user from the database based on username
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/")}

      user ->
        is_following =
          if socket.assigns.current_user.user do
            Accounts.is_following?(socket.assigns.current_user.user, user)
          else
            false
          end

        # Check if user is live
        active_stream = Streaming.get_active_stream_for_user(user.id)

        socket =
          socket
          |> assign(user: user)
          |> assign(active_tab: "home")
          |> assign(is_following: is_following)
          |> assign(follower_count: Accounts.get_followers_count(user))
          |> assign(following_count: Accounts.get_following_count(user))
          |> assign(is_live: !!active_stream)

        {:ok, socket}
    end
  end

  def handle_event("set_active_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("toggle_follow", _params, socket) do
    current_user = socket.assigns.current_user.user
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
           |> assign(follower_count: socket.assigns.follower_count - 1)}
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
end
