defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use KameramaniPhxWeb, :live_view
  alias KameramaniPhx.Accounts

  def mount(%{"username" => username}, _session, socket) do
    # Fetch user from the database based on username
    user = Accounts.get_user_by_username(username)

    if user do
      {:ok, assign(socket, user: user, active_tab: "home")}
    else
      {:ok, assign(socket, user: nil, active_tab: "home")}
    end
  end

  def handle_event("set_active_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
