defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use KameramaniPhxWeb, :live_view
  alias KameramaniPhx.Accounts
  import KameramaniPhxWeb.ProfileComponents
  alias KameramaniPhx.Socials
  alias KameramaniPhx.Streaming

  def mount(_params, _session, socket) do
    {:ok, assign(socket, user: nil, is_live: false, page_title: "User Profile")}
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

        is_following =
          if socket.assigns.current_user.user do
            Accounts.is_following?(socket.assigns.current_user.user, user)
          else
            false
          end

        # Check if user is live
        active_stream = Streaming.get_active_stream_for_user(user.id)

        tab =  Map.get(params, "tab", "home")

        socket =
          socket
          |> assign(time: time)
          |> assign(avatar_url: avatar_url)
          |> assign(active_tab: tab)
          |> assign(user: user)
          |> assign(social_accounts: social_accounts)
          |> assign(is_following: is_following)
          |> assign(follower_count: Accounts.get_followers_count(user))
          |> assign(following_count: Accounts.get_following_count(user))
          |> assign(is_live: !!active_stream)

        {:noreply, socket}
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
