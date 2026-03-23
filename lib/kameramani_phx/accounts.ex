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
  alias KameramaniPhx.Accounts.VerificationRequest
  ## Database getters

  def get_all_users(opts \\ []) do
    query =
      User
      |> order_by([u], desc: u.inserted_at)
      |> preload([:social_accounts, :roles])

    case opts do
      [] ->
        query
        |> Repo.all()
        |> apply_data()

      _ ->
        query
        |> Repo.paginate(opts)
        |> Map.update!(:entries, &apply_data/1)
    end
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
      |> apply_data()
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
    |> apply_data_single()
  end

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
    |> Repo.preload(:social_accounts)
    |> Repo.preload(:roles)
    |> apply_data_single()
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if user && User.valid_password?(user, password), do: apply_data_single(user)
  end

  def get_user!(id) do
    if Ecto.UUID.cast(id) == :error do
      raise Ecto.NoResultsError, queryable: User
    end

    Repo.get!(User, id)
    |> apply_data_single()
  end

  ## User registration

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        UserNotifier.deliver_welcome_email(user)
        {:ok, user}

      error ->
        error
    end
  end

  def validate_registration(attrs) do
    %User{}
    |> User.registration_changeset(attrs, validate_unique: false)
  end

  @doc """
  Bans a user and sends an email.
  """
  def ban_user(user, reason) do
    # In a real app, you would also set a flag in the database
    # for now we only send the email as requested.
    UserNotifier.deliver_user_banned(user, reason)
  end

  @doc """
  Warns a user and sends an email.
  """
  def warn_user(user, message) do
    UserNotifier.deliver_user_warned(user, message)
  end

  @doc """
  Sends a system update email to a user.
  """
  def send_system_update(user, update_message) do
    UserNotifier.deliver_system_update(user, update_message)
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
        {apply_data_single(user), token_inserted_at}

      other ->
        other
    end
  end

  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      apply_data_single(user)
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

  def change_user_email(%User{} = user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def update_user_email(%User{} = user, token) do
    context = "change:" <> user.email

    case UserToken.verify_change_email_token_query(token, context) do
      {:ok, query} ->
        Repo.transact(fn ->
          case Repo.one(query) do
            %{sent_to: email} = _user_token ->
              with {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
                   {_count, _} <-
                     Repo.delete_all(UserToken.user_and_contexts_query(user, [context])) do
                {:ok, user}
              end

            nil ->
              {:error, :transaction_aborted}
          end
        end)

      :error ->
        {:error, :transaction_aborted}
    end
  end

  def update_user_email_simple(%User{} = user, attrs) do
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

  defp apply_data(users) do
    ids = Enum.map(users, & &1.id)
    data = fetch_user_data(ids)

    Enum.map(users, fn user ->
      merge_user_data(user, Map.get(data, user.id, %{}))
    end)
  end

  defp apply_data_single(nil), do: nil

  defp apply_data_single(%User{} = user) do
    data =
      [user.id]
      |> fetch_user_data()
      |> Map.get(user.id, %{})

    merge_user_data(user, data)
  end

  defp fetch_user_data([]), do: %{}

  defp fetch_user_data(user_ids) do
    follower_counts =
      from(f in Follow,
        where: f.followed_id in ^user_ids,
        group_by: f.followed_id,
        select: {f.followed_id, count(f.id)}
      )
      |> Repo.all()
      |> Enum.into(%{}, fn {id, count} -> {id, %{follower_count: count}} end)

    following_counts =
      from(f in Follow,
        where: f.follower_id in ^user_ids,
        group_by: f.follower_id,
        select: {f.follower_id, count(f.id)}
      )
      |> Repo.all()
      |> Enum.into(%{}, fn {id, count} -> {id, %{following_count: count}} end)

    subscriber_counts =
      from(s in Subscription,
        where: s.streamer_id in ^user_ids and s.status == "active",
        group_by: s.streamer_id,
        select: {s.streamer_id, count(s.id)}
      )
      |> Repo.all()
      |> Enum.into(%{}, fn {id, count} -> {id, %{subscriber_count: count}} end)

    live_users =
      from(s in Stream,
        where: s.user_id in ^user_ids and s.is_live == true,
        distinct: true,
        select: s.user_id
      )
      |> Repo.all()

    Enum.into(user_ids, %{}, fn id ->
      data =
        %{is_live: id in live_users}
        |> Map.merge(follower_counts[id] || %{})
        |> Map.merge(following_counts[id] || %{})
        |> Map.merge(subscriber_counts[id] || %{})

      {id, data}
    end)
  end

  defp merge_user_data(user, data) do
    struct(user, %{
      is_live: Map.get(data, :is_live, false),
      follower_count: Map.get(data, :follower_count, 0),
      following_count: Map.get(data, :following_count, 0),
      subscriber_count: Map.get(data, :subscriber_count, 0)
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

  # user wants to get verified
  def get_verified(%User{} = user, attrs \\ %{}) do
    if Repo.exists?(
         from vr in VerificationRequest, where: vr.user_id == ^user.id and vr.status == "pending"
       ) do
      {:error, :already_requested}
    else
      create_verification_request(user, attrs)
    end
  end

  defp create_verification_request(user, attrs) do
    user = Repo.preload(user, :social_accounts)

    fetch_socials =
      Enum.map(user.social_accounts, & &1.url)

    attrs =
      attrs
      |> Map.put("user_id", user.id)
      |> Map.put_new("social_links", fetch_socials)

    case %VerificationRequest{}
         |> VerificationRequest.changeset(attrs)
         |> Repo.insert() do
      {:ok, request} ->
        Notifications.notify_verification_submitted(user, request.id)
        {:ok, request}

      error ->
        error
    end
  end

  def list_verification_requests do
    Repo.all(VerificationRequest)
    |> Repo.preload(:user)
  end

  def list_pending_verification_requests do
    from(vr in VerificationRequest,
      where: vr.status == "pending",
      order_by: [desc: vr.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  def get_verification_request!(id) do
    Repo.get!(VerificationRequest, id)
    |> Repo.preload(:user)
  end

  # check request status
  def check_verification_status(%User{} = user) do
    Repo.get_by(VerificationRequest, user_id: user.id, status: "pending")
  end

  def get_latest_verification_request(%User{} = user) do
    from(vr in VerificationRequest,
      where: vr.user_id == ^user.id,
      order_by: [desc: vr.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  def get_latest_verification_request(_), do: nil

  # admin approves or rejects a verification request
  def approve_verification_request(%VerificationRequest{} = request) do
    request_changeset = VerificationRequest.changeset(request, %{"status" => "approved"})
    user = get_user!(request.user_id)
    user_changeset = User.admin_changeset(user, %{"is_verified" => true})

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:approved_request, request_changeset)
      |> Ecto.Multi.update(:verify_user, user_changeset)
      |> Repo.transaction()

    case result do
      {:ok, %{approved_request: request}} ->
        Notifications.notify_verification_approved(user, request.id)
        {:ok, result}

      error ->
        error
    end
  end

  def reject_verification_request(%VerificationRequest{} = request) do
    case request
         |> VerificationRequest.changeset(%{"status" => "rejected"})
         |> Repo.update() do
      {:ok, request} ->
        user = get_user!(request.user_id)
        Notifications.notify_verification_rejected(user, request.id)
        {:ok, request}

      error ->
        error
    end
  end
end
