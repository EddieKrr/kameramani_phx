defmodule KameramaniPhx.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias KameramaniPhx.Repo
  alias KameramaniPhx.Accounts.{User, UserToken, UserNotifier, Follow, Role, Permission}
  alias KameramaniPhx.Notifications
  alias KameramaniPhx.Subscriptions.Subscription
  alias KameramaniPhx.Subscriptions
  alias KameramaniPhx.Streaming.Stream

  ## Database getters

  def get_all_users do
    User
    |> with_user_data()
    |> Repo.all()
    |> Repo.preload(:social_accounts)
    |> Repo.preload(:roles)
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
      |> with_user_data()
      |> Repo.all()
      |> Repo.preload(:social_accounts)
      |> Repo.preload(:roles)
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
    |> populate_user_data()
  end

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
    |> Repo.preload(:social_accounts)
    |> Repo.preload(:roles)
    |> populate_user_data()
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if user && User.valid_password?(user, password), do: populate_user_data(user)
  end

  def get_user!(id) do
    Repo.get!(User, id)
    |> populate_user_data()
  end

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

    case Repo.one(query) do
      {%User{} = user, token_inserted_at} ->
        {populate_user_data(user), token_inserted_at}

      other ->
        other
    end
  end

  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      populate_user_data(user)
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

  # make the user followable by adding a followers and following assoc
  def follow_user(follower, following) do
    follower_id = if is_map(follower), do: follower.id, else: follower
    followed_id = if is_map(following), do: following.id, else: following

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
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

    if count > 0 and follower_id != followed_id do
      Notifications.notify_new_follower(get_user!(follower_id), get_user!(followed_id))
    end
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

  def subscribe_to_streamer(streamer_id, user_id, tier) when is_integer(tier) do
    Subscriptions.subscribe_to_streamer(user_id, streamer_id, tier)
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

  # user roles and permissions

  def get_roles do
    Repo.all(Role) |> Repo.preload(:permissions)
  end

  def get_role_by_name(name) do
    Repo.get_by(Role, name: name) |> Repo.preload(:permissions)
  end

  # giving users roles and permissions
  def assign_role_to_user(user, role_name) when is_binary(role_name) do
    case Repo.get_by(Role, name: role_name) do
      nil -> {:error, :role_not_found}
      role -> assign_role_to_user(user, role)
    end
  end

  def assign_role_to_user(user, %Role{} = role) do
    user = Repo.preload(user, :roles)

    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:roles, Enum.uniq([role | user.roles]))
    |> Repo.update()
  end

  # get users with roles
  def get_role_by_name(name) do
    Repo.get_by(Role, name: name)
  end

  # check if user has a role
  def user_has_role?(user, role_name) when is_binary(role_name) do
    user = Repo.preload(user, :roles)
    Enum.any?(user.roles, fn role -> role.name == role_name end)
  end

  # list all the permissions
  def list_permissions do
    Repo.all(Permission)
  end

  # check is a user has permission
  def has_permission?(user, permission_slug) when is_binary(permission_slug) do
    user = Repo.preload(user, roles: :permissions)

    Enum.any?(user.roles, fn role ->
      Enum.any?(role.permissions, fn perm -> perm.slug == permission_slug end)
    end)
  end

  defp with_user_data(query) do
    follower_counts =
      from(f in Follow,
        group_by: f.followed_id,
        select: %{user_id: f.followed_id, follower_count: count(f.id)}
      )

    following_counts =
      from(f in Follow,
        group_by: f.follower_id,
        select: %{user_id: f.follower_id, following_count: count(f.id)}
      )

    subscriber_counts =
      from(s in Subscription,
        where: s.status == "active",
        group_by: s.streamer_id,
        select: %{user_id: s.streamer_id, subscriber_count: count(s.id)}
      )

    from(u in query,
      left_join: live_stream in Stream,
      on: live_stream.user_id == u.id,
      left_join: follower_count in subquery(follower_counts),
      on: follower_count.user_id == u.id,
      left_join: following_count in subquery(following_counts),
      on: following_count.user_id == u.id,
      left_join: subscriber_count in subquery(subscriber_counts),
      on: subscriber_count.user_id == u.id,
      select_merge: %{
        is_live: coalesce(live_stream.is_live, false),
        follower_count: coalesce(follower_count.follower_count, 0),
        following_count: coalesce(following_count.following_count, 0),
        subscriber_count: coalesce(subscriber_count.subscriber_count, 0)
      }
    )
  end

  defp populate_user_data(nil), do: nil

  defp populate_user_data(%User{} = user) do
    metrics_user =
      from(u in User, where: u.id == ^user.id)
      |> with_user_data()
      |> Repo.one()

    struct(user, %{
      is_live: metrics_user.is_live,
      follower_count: metrics_user.follower_count,
      following_count: metrics_user.following_count,
      subscriber_count: metrics_user.subscriber_count
    })
  end

  # update user roles
  def update_user_roles(user, role_name) do
    case Repo.get_by(Role, name: role_name) do
      nil ->
        {:error, :role_not_found}

      role ->
        user = Repo.preload(user, :roles)

        user
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:roles, Enum.uniq([role | user.roles]))
        |> Repo.update()
    end
  end

  # removing a role from a user
  def remove_role_from_user(user, role_name) when is_binary(role_name) do
    user = Repo.preload(user, :roles)

    if !Enum.any?(user.roles, fn r -> r.name == role_name end) do
      {:error, :user_does_not_have_that_role}
    else
      new_roles = Enum.reject(user.roles, fn r -> r.name == role_name end)

      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:roles, new_roles)
      |> Repo.update()
    end
  end

  # get users with roles
  def get_users_with_role(role_name) when is_binary(role_name) do
    case Repo.get_by(Role, name: role_name) do
      nil ->
        {:error, :role_not_found}

      _ ->
        from(u in User,
          join: r in assoc(u, :roles),
          where: r.name == ^role_name,
          preload: [:roles]
        )
        |> Repo.all()
    end
  end

  # get all users that have roles
  def get_users_with_any_role do
    from(u in User,
      join: r in assoc(u, :roles),
      preload: [:roles]
    )
    |> Repo.all()
  end
end
