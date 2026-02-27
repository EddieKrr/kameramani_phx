defmodule KameramaniPhx.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias KameramaniPhx.Repo
  alias KameramaniPhx.Streaming
  alias KameramaniPhx.Accounts.{User, UserToken, UserNotifier, Follow}

  ## Database getters

  def get_all_users do
    Repo.all(User) |> Repo.preload(:social_accounts)
  end

  # list users on nav
  def list_users_by_username(_current_user, search) when is_binary(search) do
    search_query = String.trim(search)

    if search_query == "" do
      []
    else
      from(u in User,
        where: ilike(u.username, ^"%#{search_query}%"),
        order_by: [asc: u.username],
        limit: 8
      )
      |> Repo.all()
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
    |> Repo.preload(:social_accounts)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if user && User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def validate_registration(attrs) do
    %User{}
    |> User.registration_changeset(attrs, validate_unique: false)
  end

  ## Settings

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  ## Session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise "magic link log in not allowed for unconfirmed users with a password set!"

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  def change_user_email(%User{} = user, attrs, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def update_user_email(%User{} = user, attrs) do
    user
    |> User.email_changeset(attrs)
    |> Repo.update()
  end

  def change_user_profile(%User{} = user, attrs) do
    User.profile_changeset(user, attrs)
  end

  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  # lets make the user followable by adding a followers and following association
  def follow_user(follower, following) do
    follower_id = if is_map(follower), do: follower.id, else: follower
    followed_id = if is_map(following), do: following.id, else: following

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all(
      Follow,
      [
        [
          follower_id: follower_id,
          followed_id: followed_id,
          inserted_at: now,
          updated_at: now
        ]
      ],
      on_conflict: :nothing
    )
  end

  # unfollow a user
  def unfollow_user(follower, following) do
    follower_id = if is_map(follower), do: follower.id, else: follower
    followed_id = if is_map(following), do: following.id, else: following

    query =
      from f in Follow,
        where: f.follower_id == ^follower_id and f.followed_id == ^followed_id

    Repo.delete_all(query)
  end

  def is_following?(follower, following) do
    follower_id = if is_map(follower), do: follower.id, else: follower
    followed_id = if is_map(following), do: following.id, else: following

    query =
      from f in Follow,
        where: f.follower_id == ^follower_id and f.followed_id == ^followed_id

    Repo.exists?(query)
  end

  def get_followers_count(user) do
    user_id = if is_map(user), do: user.id, else: user
    query = from f in Follow, where: f.followed_id == ^user_id
    Repo.aggregate(query, :count)
  end

  def get_following_count(user) do
    user_id = if is_map(user), do: user.id, else: user
    query = from f in Follow, where: f.follower_id == ^user_id
    Repo.aggregate(query, :count)
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:" <> current_email)
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  def change_user_email(user, _current_email, new_email, password) do
    email_changes = User.email_changeset(user, %{email: new_email})
    password_changes = User.password_changeset(user, %{password: password})

    changeset = Ecto.Changeset.merge(email_changes, password_changes)
    Repo.update(changeset)
  end

  def change_user_email(user, _current_email, new_email, password, extra_attrs) do
    email_changes = User.email_changeset(user, %{email: new_email})
    password_changes = User.password_changeset(user, %{password: password})

    changeset =
      Ecto.Changeset.merge(email_changes, password_changes)
      |> Ecto.Changeset.cast(extra_attrs, :map, [])

    Repo.update(changeset)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)
        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))
        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
