defmodule KameramaniPhxWeb.StudioLive do
  use KameramaniPhxWeb, :live_view

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}
  import KameramaniPhxWeb.CoreComponents

  @default_stream_settings %{
    "title" => "My First Stream",
    "game" => "Just Chatting",
    "stream_key" => "live_sk_12345_SECRET"
  }

  def mount(_params, _session, socket) do
    form = to_form(@default_stream_settings, as: :stream_settings)

    {:ok,
     assign(socket,
       form: form,
       stream_key_visible: false

     )}
  end

  def handle_event("validate", %{"stream_settings" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: :stream_settings))}
  end

  def handle_event("save", %{"stream_settings" => params}, socket) do
    IO.inspect(params, label: "SAVING CONFIG")
    {:noreply, put_flash(socket, :info, "Stream info updated!")}
  end

  def handle_event("toggle_key", _, socket) do
    {:noreply, assign(socket, stream_key_visible: !socket.assigns.stream_key_visible)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Creator Studio")}
  end
end
