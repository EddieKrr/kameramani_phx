defmodule KameramaniPhx.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias KameramaniPhx.Repo

  schema "users" do
    field :name, :string
    field :username, :string
    field :age, :integer
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :bio, :string
    field :profile_picture, :string
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    many_to_many :following, KameramaniPhx.Accounts.User,
    join_through: "follows",
    join_keys: [follower_id: :id, followed_id: :id]
    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name, :username, :email, :age, :password])
    |> validate_required([:name, :username, :email, :age, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, KameramaniPhx.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:password])
      |> validate_length(:password, min: 6, max: 72)

    if Keyword.get(opts, :hash_password, true) do
      changeset
      |> maybe_hash_password()
    else
      changeset
    end
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def update_user_password(user, new_password) do
    changeset = change(user, password: new_password)
    |> validate_password([])
    case Repo.update(changeset) do
      {:ok, updated_user} ->
        {:noreply, updated_user}
      {:error, changeset} ->
        {:error, changeset}
    end
  end


  #update user stream profile
  def profile_changeset(user, attr) do
    user
    |> cast(attr, [:username,:bio, :profile_picture])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_length(:bio, max: 160)
    |>unsafe_validate_unique(:username, KameramaniPhx.Repo)
    |> unique_constraint(:username)
  end
  @doc """
  Verifies the password.
  """
  def valid_password?(%KameramaniPhx.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end




end
