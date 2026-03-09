defmodule KameramaniPhxWeb.AdminLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:all")
    end

    menu_items = [
      %{id: "users", label: "Users", path: ~p"/admin/users"},
      %{id: "categories", label: "Categories", path: ~p"/admin/categories"},
      %{id: "tags", label: "Tags", path: ~p"/admin/tags"},
      %{id: "access", label: "Access Control", path: ~p"/admin/access"},
      %{id: "settings", label: "Settings", path: ~p"/admin/settings"}
    ]

    active_tab = "users"

    users = KameramaniPhx.Accounts.get_all_users()

    {:ok,
     assign(socket,
       page_bg_class: "bg-blue-200",
       layout_type: :admin,
       active_tab: active_tab,
       users: users,
       menu_items: menu_items
     )}
  end

  @impl true
  def handle_event("some_admin_action", _value, socket) do
    # Handle admin-specific events here
    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"tab" => current_tab}, _uri, socket) do
    {:noreply, assign(socket, active_tab: current_tab)}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, assign(socket, active_tab: "users")}
  end

  @impl true
  def handle_info({:stream_status_updated, updated_stream}, socket) do
    users =
      Enum.map(socket.assigns.users, fn user ->
        if user.id == updated_stream.user_id do
          %{user | is_live: updated_stream.is_live}
        else
          user
        end
      end)

    {:noreply, assign(socket, users: users)}
  end
end
