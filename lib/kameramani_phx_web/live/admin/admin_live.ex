defmodule KameramaniPhxWeb.AdminLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.AdminComponents

  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Streaming

  @users_page_size 6
  @streams_page_size 6

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:all")
    end

    current_user = socket.assigns.current_user.user

    all_menu_items = [
      %{id: "users", label: "Users", path: ~p"/admin/users"},
      %{id: "categories", label: "Categories", path: ~p"/admin/categories"},
      %{id: "tags", label: "Tags", path: ~p"/admin/tags"},
      %{id: "access", label: "Access Control", path: ~p"/admin/access"},
      %{id: "settings", label: "Settings", path: ~p"/admin/settings"}
    ]

    is_moderator = KameramaniPhx.Accounts.user_has_role?(current_user, "moderator")

    menu_items =
      if is_moderator do
        Enum.reject(all_menu_items, &(&1.id in ["access", "settings"]))
      else
        all_menu_items
      end

    active_tab = "users"


    users_page = Accounts.get_all_users(page: 1, page_size: @users_page_size)
    live_streams_page = Streaming.list_live_streams(page: 1, page_size: @streams_page_size)

    {:ok,
     assign(socket,
       page_bg_class: "bg-blue-200",
       layout_type: :admin,
       active_tab: active_tab,
       allowed_tabs: Enum.map(menu_items, & &1.id),
       users_page: users_page,
       live_streams_page: live_streams_page,
       menu_items: menu_items
     )}
  end

  @impl true
  def handle_event("some_admin_action", _value, socket) do
    # Handle admin-specific events here
    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate_users", %{"page" => page}, socket) do
    page_number = page_param(page, socket.assigns.users_page.page_number)

    users_page =
      Accounts.get_all_users(page: page_number, page_size: @users_page_size)

    {:noreply, assign(socket, users_page: users_page)}
  end

  @impl true
  def handle_event("paginate_streams", %{"page" => page}, socket) do
    page_number = page_param(page, socket.assigns.live_streams_page.page_number)

    live_streams_page =
      Streaming.list_live_streams(page: page_number, page_size: @streams_page_size)

    {:noreply, assign(socket, live_streams_page: live_streams_page)}
  end

  @impl true
  def handle_params(%{"tab" => current_tab}, _uri, socket) do
    if current_tab in socket.assigns.allowed_tabs do
      {:noreply, assign(socket, active_tab: current_tab)}
    else
      fallback_tab = hd(socket.assigns.allowed_tabs)

      {:noreply,
       socket
       |> put_flash(:error, "You do not have access to that admin section.")
       |> push_patch(to: ~p"/admin/#{fallback_tab}")}
    end
  end

  @impl true
  def handle_params(_, _, socket) do

    {:noreply, assign(socket, active_tab: "users")}
  end

  @impl true
  def handle_info({:stream_status_updated, updated_stream}, socket) do
    entries =
      Enum.map(socket.assigns.users_page.entries, fn user ->
        if user.id == updated_stream.user_id do
          %{user | is_live: updated_stream.is_live}
        else
          user
        end
      end)

    live_streams_page =
      Streaming.list_live_streams(
        page: socket.assigns.live_streams_page.page_number,
        page_size: @streams_page_size
      )

    {:noreply,
     socket
     |> assign(
       users_page: %{socket.assigns.users_page | entries: entries},
       live_streams_page: live_streams_page
     )}
  end

  defp page_param(value, default) do
    case Integer.parse(to_string(value || "")) do
      {int, ""} when int >= 1 ->
        int

      _ ->
        default || 1
    end
  end
end
