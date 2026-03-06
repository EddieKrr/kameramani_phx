defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use KameramaniPhxWeb, :live_view
  alias KameramaniPhx.Accounts
  import KameramaniPhxWeb.ProfileComponents
  import Ecto.Query
  alias KameramaniPhx.Repo
  alias KameramaniPhx.Socials
  alias KameramaniPhx.Streaming

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:all")
    end

    {:ok, assign(socket, user: nil, is_live: false, stream_id: nil, active_stream: nil)}
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

        current_user =
          case socket.assigns[:current_user] do
            %{user: user} -> user
            _ -> nil
          end

        is_following =
          if current_user do
            Accounts.is_following?(current_user, user)
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
          |> assign(follower_count: Accounts.get_followers_count(user))
          |> assign(following_count: Accounts.get_following_count(user))
          |> assign(is_live: !!active_stream)
          |> assign(stream_id: if(active_stream, do: active_stream.id, else: nil))
          |> assign(active_stream: active_stream)
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

  defp list_vods(user_id) do
    query =
      from(v in KameramaniPhx.Streaming.Stream,
        where: v.user_id == ^user_id and v.is_live == false,
        preload: [:user]
      )

    Repo.all(query)
  end
end
