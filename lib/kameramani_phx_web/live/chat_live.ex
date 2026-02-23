defmodule KameramaniPhxWeb.ChatLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents

  # Alias DummyData for shared hardcoded data
  alias KameramaniPhxWeb.DummyData
  # Correct alias for Accounts context
  alias KameramaniPhx.Accounts
  # Alias Scope module directly
  alias KameramaniPhx.Accounts.Scope

  # Keep your mount user
  # on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user} # Removed

  @initial_state %{"ch_message" => ""}

  # --- INTERN'S PUBSUB LOGIC (Integrated) ---
  defp subscribe(stream_id) do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "stream_chat:#{stream_id}")
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "stream_state:#{stream_id}")
  end

  defp broadcast(stream_id, value) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "stream_chat:#{stream_id}", value)
  end

  def mount(%{"username" => username}, session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:halt, socket |> Phoenix.LiveView.put_flash(:error, "User not found") |> Phoenix.LiveView.redirect(to: ~p"/")}

      user ->
        # Fetch the stream for this user
        case KameramaniPhx.Streaming.get_active_stream_for_user(user.id) do
          nil ->
            {:halt, socket |> Phoenix.LiveView.put_flash(:error, "Stream not found") |> Phoenix.LiveView.redirect(to: ~p"/")}

          stream ->
            # Found real data, assign to socket
            assigns_to_socket = %{
              stream_id: stream.id,
              streamer_name: user.username,
              streamer_profile_picture: user.profile_picture || "/images/default-avatar.png",
              category_name: stream.category || "Just Chatting",
              stream_name: stream.title,
              tags: stream.tags || [],
              is_live: stream.is_live
            }

            # Manually mount current_user (without enforcing authentication)
            current_user_scope =
              if user_token = session["user_token"] do
                {curr_user, _} = Accounts.get_user_by_session_token(user_token) || {nil, nil}
                Scope.for_user(curr_user)
              else
                Scope.for_user(nil)
              end

            # Subscribe if connected so we receive live messages
            if connected?(socket), do: subscribe(assigns_to_socket.stream_id)

            # If the current user is logged in, use their username and a consistent color
            {chat_username, chat_user_color} = if current_user_scope.user do
               {current_user_scope.user.username, "#6366f1"}
            else
               {Enum.random(["Guest_#{:rand.uniform(1000)}"]), "#" <> (for _ <- 1..3, into: "", do: Integer.to_string(Enum.random(100..255), 16))}
            end

            {:ok,
             socket
             |> assign(
               form: to_form(@initial_state, as: :chat),
               username: chat_username,
               user_color: chat_user_color,
               current_user: current_user_scope
             )
             |> assign(assigns_to_socket)
             |> stream(:messages, [])}
        end
    end
  end

  def handle_event("send_message", %{"chat" => %{"ch_message" => message_text}}, socket) do
    # Check if user is logged in
    if socket.assigns.current_user.user do
      message = String.trim(message_text)

      if message != "" do
        nai_time = DateTime.now!("Africa/Nairobi")
        nu_time = KameramaniPhxWeb.Cldr.Time.to_string!(nai_time, format: :medium)

        new_message = %{
          id: System.unique_integer([:positive]),
          name: socket.assigns.username,
          text: message,
          dt: nu_time,
          color: socket.assigns.user_color
        }

        # Broadcast to everyone (including yourself)
        broadcast(socket.assigns.stream_id, {:new_message, new_message})

        {:noreply, assign(socket, form: to_form(@initial_state, as: :chat))}
      else
        {:noreply, socket}
      end
    else
      # User not logged in, show flash message and don't send message
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to chat.")
        # Clear form even if not logged in
        |> assign(form: to_form(@initial_state, as: :chat))

      {:noreply, socket}
    end
  end

  def handle_event("validate", %{"chat" => %{"ch_message" => message}}, socket) do
    form = to_form(%{"ch_message" => message}, as: :chat)
    {:noreply, assign(socket, form: form)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: socket.assigns.streamer_name <> " | Chat")}
  end

  # This function will handle messages broadcasted via PubSub
  def handle_info({:new_message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info({:stream_status, status}, socket) do
    is_live = (status == :online)
    {:noreply, assign(socket, is_live: is_live)}
  end
end
