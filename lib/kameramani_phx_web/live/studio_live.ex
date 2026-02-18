defmodule KameramaniPhxWeb.StudioLive do
  alias KameramaniPhx.Streaming
  alias KameramaniPhx.Content
  # alias KameramaniPhx.PubSub # Removed as it's not directly used here

  use KameramaniPhxWeb, :live_view

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}
  import KameramaniPhxWeb.CoreComponents

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user.user
    changeset = Streaming.change_stream(%Streaming.Stream{}, %{user_id: user.id})
    categories = Content.list_categories()
    stream = Streaming.get_active_stream_for_user(user.id)

    # Subscribe to stream updates for this user
    if stream, do: Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:#{stream.id}")

    {:ok,
     socket
     |> assign(page_title: "Creator Studio")
     |> assign(:stream_form, to_form(changeset))
     |> assign(:categories, categories)
     |> assign(:current_stream, stream)
     |> assign(selected_category_id: nil)}
  end

  def handle_info({:stream_status_updated, %Streaming.Stream{} = updated_stream}, socket) do
    if socket.assigns.current_stream && socket.assigns.current_stream.id == updated_stream.id do
      {:noreply, assign(socket, :current_stream, updated_stream)}
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
        # Start the streaming pipeline for this stream
        pipeline_id = String.to_atom("stream_pipeline_#{stream_id}")
        hls_output_dir = Path.join(["priv", "static", "live", stream_id])

        # Ensure output directory exists
        File.mkdir_p!(hls_output_dir)

        # Start the pipeline
        {:ok, _pid} = KameramaniPhxWeb.Streaming.Pipeline.start_link(pipeline_id, hls_output_dir)

        # Register the pipeline
        KameramaniPhx.StreamManager.add_stream(stream_id, pipeline_id)

        socket =
          socket
          |> put_flash(:info, "Stream setup complete! Get your stream key to start broadcasting.")
          |> assign(:current_stream, stream)
          |> assign(:stream_form, to_form(Streaming.change_stream(%Streaming.Stream{}, %{user_id: user.id}))) # Reset form
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

  def handle_event("select_category", %{"category_id" => category_id}, socket) do
    {:noreply, assign(socket, selected_category_id: category_id)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Creator Studio")}
  end
end
