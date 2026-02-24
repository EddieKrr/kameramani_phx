defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use KameramaniPhxWeb, :live_view
  alias KameramaniPhx.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, user: nil, is_live: false)}
  end

  def handle_params(%{"username" => username}, uri, socket) do
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
