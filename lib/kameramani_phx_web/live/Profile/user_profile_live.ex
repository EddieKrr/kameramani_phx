defmodule KameramaniPhxWeb.Profile.UserProfileLive do
  use Phoenix.LiveView
  alias KameramaniPhx.Users
  alias KameramaniPhx.Repo
  alias KameramaniPhx.Users.User
  alias KameramaniPhx.Accounts

  def mount(%{"username" => username}, _session, socket) do
    # Fetch the user from the database based on the username
    user = Accounts.get_user_by_username(username)

    if user do
      {:ok, assign(socket, user: user)}
    else
      {:ok, assign(socket, user: nil)}
    end
  end
end
