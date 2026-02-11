defmodule KameramaniPhxWeb.ChatLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents

  # Keep your mount scope
  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_scope}

  @initial_state %{"ch_message" => ""}

  # --- INTERN'S PUBSUB LOGIC (Integrated) ---
  defp subscribe() do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "messages")
  end

  defp broadcast(value) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "messages", value)
  end

  def mount(%{"stream_id" => stream_id}, _session, socket) do
    # Subscribe if connected so we receive live messages
    if connected?(socket), do: subscribe()

    username = Enum.random(["BIG C", "Canna", "Bis", "Mafrr"])
    user_color = "#" <> for _ <- 1..3, into: "", do: Integer.to_string(Enum.random(100..255), 16)

    {:ok,
     socket
     |> assign(
       form: to_form(@initial_state, as: :chat),
       username: username,
       user_color: user_color,
       stream_id: stream_id,
       game: "Sims 4"
     )
     |> stream(:messages, [])}
  end

  def handle_event("send_message", %{"chat" => %{"ch_message" => message}}, socket) do
    message = String.trim(message)

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
      broadcast({:new_message, new_message})

      {:noreply, assign(socket, form: to_form(@initial_state, as: :chat))}
    else
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
      |> assign(page_title: "Chat")}
  end
end
