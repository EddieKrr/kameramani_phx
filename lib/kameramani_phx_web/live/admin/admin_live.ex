defmodule KameramaniPhxWeb.AdminLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    menu_items = [
      %{id: "users", label: "Users", path: ~p"/admin/users"},
      %{id: "categories", label: "Categories", path: ~p"/admin/categories"},
      %{id: "tags", label: "Tags", path: ~p"/admin/tags"},
      %{id: "access", label: "Access Control", path: ~p"/admin/access"},
      %{id: "settings", label: "Settings", path: ~p"/admin/settings"}
    ]

    active_tab = :categories

    {:ok,
     assign(socket,
       page_bg_class: "bg-blue-200",
       layout_type: :admin,
       active_tab: active_tab,
       menu_items: menu_items
     )}
  end

  @impl true
  def handle_event("some_admin_action", _value, socket) do
    # Handle admin-specific events here
    {:noreply, socket}
  end

  def handle_params(%{"tab" => current_tab}, _uri, socket) do

    {:noreply, assign(socket, active_tab: current_tab)}
  end

  def handle_params(_, _, socket) do
    {:noreply, assign(socket, active_tab: "users")}
  end
end
