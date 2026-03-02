defmodule KameramaniPhxWeb.ChatLiveComponent do
  use KameramaniPhxWeb, :live_component
  alias KameramaniPhx.Chat

  @initial_state %{"ch_message" => ""}

  defp subscribe(stream_id) do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "stream_chat:#{stream_id}")
  end

  defp broadcast(stream_id, value) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "stream_chat:#{stream_id}", value)
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(form: to_form(@initial_state, as: :chat), subscribed: false)}
  end

  @impl true
  def update(assigns, socket) do
    stream_id = assigns.stream_id

    # If we received a new_message via send_update from parent LiveView
    socket =
      if message = assigns[:new_message] do
        stream_insert(socket, :messages, message)
      else
        assign(socket, assigns)
      end

    socket =
      if !socket.assigns.subscribed do
        if connected?(socket), do: subscribe(stream_id)
        messages = Chat.list_messages_for_stream(stream_id)

        socket
        |> stream(:messages, messages)
        |> assign(subscribed: true)
      else
        socket
      end

    current_user = socket.assigns.current_user
    chat_colors = ~w(#3b82f6 #ef4444 #f97316 #eab308 #ec4899 #a855f7 #22c55e #84cc16)

    {chat_username, chat_user_color} =
      if current_user do
        {current_user.username, current_user.chat_color || "#6366f1"}
      else
        {Enum.random(["Guest_#{:rand.uniform(1000)}"]), Enum.random(chat_colors)}
      end

    socket =
      socket
      |> assign(username: chat_username, user_color: chat_user_color)

    {:ok, socket}
  end

  @impl true
  def handle_event("send_message", %{"chat" => %{"ch_message" => message_text}}, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      message_body = String.trim(message_text)

      if message_body != "" do
        attrs = %{
          body: message_body,
          stream_id: socket.assigns.stream_id,
          user_id: current_user.id
        }

        case Chat.create_stream_message(attrs) do
          {:ok, message} ->
            message = Map.put(message, :user, current_user)
            broadcast(socket.assigns.stream_id, {:new_message, message})
            {:noreply, assign(socket, form: to_form(@initial_state, as: :chat))}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not send message")}
        end
      else
        {:noreply, socket}
      end
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to chat.")
        |> assign(form: to_form(@initial_state, as: :chat))

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"chat" => %{"ch_message" => message}}, socket) do
    form = to_form(%{"ch_message" => message}, as: :chat)
    {:noreply, assign(socket, form: form)}
  end
end
