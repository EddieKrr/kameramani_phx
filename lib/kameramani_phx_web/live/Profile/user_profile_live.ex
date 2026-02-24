defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use KameramaniPhxWeb, :live_view
  alias KameramaniPhx.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, user: nil, is_live: false)}
  end

  def handle_params(%{"username" => username}, uri, socket) do
    user = Accounts.get_user_by_username(username)

    if user do
      {:noreply, assign(socket, user: user, is_live: true)}
    else
      {:noreply, assign(socket, user: nil, is_live: false)}
    end
  end
end
