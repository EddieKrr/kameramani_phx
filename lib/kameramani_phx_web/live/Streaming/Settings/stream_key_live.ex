defmodule KameramaniPhxWeb.Streaming.Settings.StreamKeyLive do
  use KameramaniPhxWeb, :live_view

  alias KameramaniPhx.Streaming
  # alias KameramaniPhx.Accounts.User # Removed as it's not used

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}
  import KameramaniPhxWeb.CoreComponents

  def mount(_params, _session, socket) do
    user = case socket.assigns.current_user do
      %{user: user} -> user  # Scope struct
      user -> user           # Direct User struct
    end
    stream = Streaming.get_active_stream_for_user(user.id)

    stream_key = if stream, do: stream.stream_key, else: nil

    {:ok,
     socket
     |> assign(page_title: "Stream Key Settings")
     |> assign(:current_user, user)
     |> assign(:stream, stream)
     |> assign(:stream_key, stream_key)
     |> assign(stream_key_visible: false)
    }
  end

  def handle_event("generate_stream_key", _params, socket) do
    user = case socket.assigns.current_user do
      %{user: user} -> user  # Scope struct
      user -> user           # Direct User struct
    end
    case Streaming.get_active_stream_for_user(user.id) do
      nil ->
        # If no stream exists, create one with a new key
        {:ok, stream} = Streaming.create_stream(%{user_id: user.id, title: "My Stream"})
        {:noreply,
         socket
         |> put_flash(:info, "New stream created and key generated!")
         |> assign(:stream, stream)
         |> assign(:stream_key, stream.stream_key)
        }
      stream ->
        # If a stream exists, reset its key
        new_key = Streaming.generate_stream_key(user.id)
        {:ok, updated_stream} = Streaming.update_stream(stream, %{stream_key: new_key})
        {:noreply,
         socket
         |> put_flash(:info, "Stream key regenerated!")
         |> assign(:stream, updated_stream)
         |> assign(:stream_key, updated_stream.stream_key)
        }
    end
  end

  def handle_event("toggle_key_visibility", _params, socket) do
    {:noreply, assign(socket, stream_key_visible: !socket.assigns.stream_key_visible)}
  end

  def handle_event("copy_stream_key", _params, socket) do
    {:noreply, socket |> put_flash(:info, "Stream key copied to clipboard (functionality handled by JS).")}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
