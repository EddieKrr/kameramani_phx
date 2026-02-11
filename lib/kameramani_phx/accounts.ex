defmodule KameramaniPhx.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias KameramaniPhx.Repo

  alias KameramaniPhx.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
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


#user following feature
def follow_user(follower_id, followed_id) do

  Repo.insert_all("follows", [[
    follower_id: follower_id,
    followed_id: followed_id,
    inserted_at: DateTime.utc_now(),
    updated_at: DateTime.utc_now()
  ]])
end

#unfollow a user

def unfollow_user(follower_id, followed_id) do
  Repo.delete_all(from(f in "follows", where: [follower_id: ^follower_id, followed_id: ^followed_id]))
end








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

  def update_user_password(%User{} = user, new_password) do
    User.update_user_password(user, new_password)
  end

  def change_user_email(%User{} = user, attrs, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def update_user_email(%User{} = user, attrs) do
    user
    |> User.email_changeset(attrs)
    |> Repo.update()
  end

  def change_user_password(%User{} = user, attrs, opts \\ []) do
    User.password_changeset(user, attrs, opts)
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

  def change_user_email(user, current_email, new_email) do
    user
    |> User.email_changeset(current_email, new_email)
    |> Repo.update()
  end

  def change_user_email(user, current_email, new_email, password) do
    user
    |> User.email_changeset(current_email, new_email)
    |> User.password_changeset(password)
    |> Ecto.Changeset.merge()
    |> Repo.update()
  end

  def change_user_email(user, current_email, new_email, password, extra_attrs) do
    changeset =
      user
      |> User.email_changeset(current_email, new_email)
      |> User.password_changeset(password)
      |> Ecto.Changeset.merge()
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

  defp user_registration_changeset(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
  end

  defp user_email_changeset(user, current_email, new_email) do
    user
    |> Ecto.Changeset.change(:email, current_email)
    |> Ecto.Changeset.put_change(:email, new_email)
    |> Ecto.Changeset.validate_required(:email)
    |> Ecto.Changeset.validate_format(:email)
    |> Ecto.Changeset.validate_length(:email, 3, 160)
    |> Ecto.Changeset.validate_format(:email, ~r/@/)
  end

  defp user_password_changeset(password) do
    Ecto.Changeset.change(%User{}, :password)
    |> Ecto.Changeset.validate_required(:password)
    |> Ecto.Changeset.validate_length(:password, 12, 80)
    |> Ecto.Changeset.validate_format(:password, ~r/^(?=.*[a-z]+?=.*[0-9])|(?=.*[a-z]+.*$)/)
    |> Ecto.Changeset.put_change(:hashed_password, Pbkdf2.Base.hash_password(password, "some_salt"))
  end

  defp user_confirm_changeset(user) do
    user
    |> Ecto.Changeset.change(:confirmed_at)
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now())
  end
end
