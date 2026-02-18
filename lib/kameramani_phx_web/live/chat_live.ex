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
  end

  defp broadcast(stream_id, value) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "stream_chat:#{stream_id}", value)
  end

  def mount(%{"username" => username}, session, socket) do
    # Find the streamer's data in the shared hardcoded list
    case Enum.find(DummyData.get_stream_data(), fn s -> s.streamer == username end) do
      %{
        id: id,
        stream_name: name,
        streamer: streamer_name,
        avatar: avatar,
        category: category,
        tags: tags
      } ->
        # Found in hardcoded data, assign to socket
        assigns_to_socket = %{
          stream_id: id,
          streamer_name: streamer_name,
          streamer_profile_picture: avatar,
          category: category,
          stream_name: name,
          tags: tags
        }

        # Manually mount current_user (without enforcing authentication)
        current_user_scope =
          if user_token = session["user_token"] do
            {user, _} = Accounts.get_user_by_session_token(user_token) || {nil, nil}
            Scope.for_user(user)
          else
            Scope.for_user(nil)
          end

        # Subscribe if connected so we receive live messages
        if connected?(socket), do: subscribe(assigns_to_socket.stream_id)

        chat_username = Enum.random(["BIG C", "Canna", "Bis", "Mafrr"])

        chat_user_color =
          "#" <> for _ <- 1..3, into: "", do: Integer.to_string(Enum.random(100..255), 16)

        {:ok,
         socket
         |> assign(
           form: to_form(@initial_state, as: :chat),
           # This is the chat user's display name
           username: chat_username,
           user_color: chat_user_color,
           # Assign current_user
           current_user: current_user_scope
         )
         # Assign all the streamer/stream related data
         |> assign(assigns_to_socket)
         |> stream(:messages, [])}

      # Not found in hardcoded data, redirect
      _ ->
        {:halt, socket |> Phoenix.LiveView.redirect(to: ~p"/")}
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
end
