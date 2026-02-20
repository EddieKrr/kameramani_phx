defmodule KameramaniPhxWeb.StudioLive do
  alias KameramaniPhx.Streaming
  alias KameramaniPhx.Content
  require Logger

  use KameramaniPhxWeb, :live_view

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}
  import KameramaniPhxWeb.CoreComponents

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user.user
    changeset = Streaming.change_stream(%Streaming.Stream{}, %{user_id: user.id})
    categories = Content.list_categories()
    stream = Streaming.get_active_stream_for_user(user.id)

    # Subscribe to stream updates for this user
    if stream do
      Logger.info("Studio Live: Subscribing to stream updates for stream_id=#{stream.id}")
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:#{stream.id}")
    end

    {:ok,
     socket
     |> assign(page_title: "Creator Studio")
     |> assign(:stream_form, to_form(changeset))
     |> assign(:categories, categories)
     |> assign(:current_stream, stream)
     |> assign(:stream_is_live, stream && stream.is_live)
     |> assign(selected_category_name: nil)}
  end

  def handle_info({:stream_status_updated, %Streaming.Stream{} = updated_stream}, socket) do
    Logger.info("Studio Live: Stream status updated - is_live=#{updated_stream.is_live}")
    if socket.assigns.current_stream && socket.assigns.current_stream.id == updated_stream.id do
      {:noreply,
       socket
       |> assign(:current_stream, updated_stream)
       |> assign(:stream_is_live, updated_stream.is_live)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate", %{"stream" => params}, socket) do
    changeset =
      %Streaming.Stream{}
      |> Streaming.change_stream(Map.put(params, "user_id", socket.assigns.current_user.user.id))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, stream_form: to_form(changeset))}
  end

  def handle_event("create_stream", %{"stream" => stream_params}, socket) do
    user = socket.assigns.current_user.user

    stream_params =
      case Map.get(stream_params, "tags") do
        tags_str when is_binary(tags_str) ->
          Map.put(stream_params, "tags", String.split(tags_str, ",", trim: true))

        _ ->
          stream_params
      end

    attrs = Map.put(stream_params, "user_id", user.id)

    case Streaming.create_stream(attrs) do
      {:ok, stream = %Streaming.Stream{id: stream_id}} ->
        socket =
          socket
          |> put_flash(:info, "Stream setup complete! Get your stream key to start broadcasting.")
          |> assign(:current_stream, stream)
          # Reset form
          |> assign(
            :stream_form,
            to_form(Streaming.change_stream(%Streaming.Stream{}, %{user_id: user.id}))
          )
          |> push_navigate(to: "/users/settings/stream-key")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to create stream.")
          |> assign(:stream_form, to_form(changeset))

        {:noreply, socket}
    end
  end

  def handle_event("select_category", %{"category_name" => category_name}, socket) do
    {:noreply, assign(socket, selected_category_name: category_name)}
  end

  def handle_event("reset_stream", _params, socket) do
    user = socket.assigns.current_user.user
    current_stream = socket.assigns.current_stream

    if current_stream && !current_stream.is_live do
      # Delete the old stream entry so they can start fresh
      Streaming.delete_stream(current_stream)
    end

    changeset = Streaming.change_stream(%Streaming.Stream{}, %{user_id: user.id})

    {:noreply,
     socket
     |> assign(:current_stream, nil)
     |> assign(:stream_is_live, false)
     |> assign(:stream_form, to_form(changeset))
     |> assign(:selected_category_name, nil)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Creator Studio")}
  end
end
