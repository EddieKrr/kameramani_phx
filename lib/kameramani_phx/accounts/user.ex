defmodule KameramaniPhx.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @allowed_domains ~w(gmail.com yahoo.com outlook.com hotmail.com icloud.com protonmail.com aol.com mail.com)

  schema "users" do
    field :name, :string
    field :username, :string
    field :age, :integer
    field :email, :string
    field :hashed_password, :string
    field :confirmed_at, :utc_datetime
    field :bio, :string
    field :profile_picture, :string
    field :chat_color, :string
    field :mobile_number, :string
    field :accounts, {:array, :map}, default: []
    field :is_verified, :boolean, default: false

    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true
    field :current_password, :string, virtual: true, redact: true
    field :authenticated_at, :utc_datetime, virtual: true

    field :is_live, :boolean, virtual: true, default: false
    field :follower_count, :integer, virtual: true, default: 0
    field :following_count, :integer, virtual: true, default: 0
    field :subscriber_count, :integer, virtual: true, default: 0

    has_many :social_accounts, KameramaniPhx.Socials.SocialAccount
    has_many :verification_requests, KameramaniPhx.Accounts.VerificationRequest
    has_many :followers, KameramaniPhx.Accounts.Follow, foreign_key: :followed_id
    has_many :following, KameramaniPhx.Accounts.Follow, foreign_key: :follower_id
    has_many :subscribers, KameramaniPhx.Subscriptions.Subscription, foreign_key: :streamer_id
    has_many :subscriptions, KameramaniPhx.Subscriptions.Subscription, foreign_key: :subscriber_id

    many_to_many :roles, KameramaniPhx.Accounts.Role, join_through: "user_roles"

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name, :username, :age, :email, :password, :chat_color])
    |> validate_required([:name, :username, :age, :email, :password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_email(opts)
    |> maybe_put_chat_color()
    |> maybe_hash_password(opts)
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :bio, :profile_picture])
  end

  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_confirmation(:password, message: "does not match password")
    |> case do
      %{changes: %{password: _}} = changeset ->
        if Keyword.get(opts, :hash_password, true) do
          maybe_hash_password(changeset, opts)
        else
          changeset
        end

      %{} = changeset ->
        changeset
    end
  end

  def confirm_changeset(user) do
    change(user, confirmed_at: DateTime.utc_now(:second))
  end

  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_verified])
  end

  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    changeset =
      if changeset.valid? do
        validate_allowed_domain(changeset)
      else
        changeset
      end

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, KameramaniPhx.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp validate_allowed_domain(changeset) do
    case get_field(changeset, :email) do
      nil ->
        changeset

      email ->
        domain = email |> String.split("@") |> List.last() |> String.downcase()

        if domain in @allowed_domains do
          changeset
        else
          add_error(changeset, :email, "must be from a supported provider (Gmail, Yahoo, etc.)")
        end
    end
  end

  defp maybe_hash_password(changeset, opts) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> maybe_validate_password_hash(opts)
    else
      changeset
    end
  end

  defp maybe_validate_password_hash(changeset, opts) do
    if Keyword.get(opts, :validate_password_hash, true) do
      changeset
    else
      changeset
    end
  end

  defp maybe_put_chat_color(changeset) do
    if get_field(changeset, :chat_color) do
      changeset
    else
      put_change(changeset, :chat_color, Enum.random(~w(#6366f1 #f97316 #22c55e #eab308 #ef4444 #ec4899 #3b82f6 #84cc16 #a855f7)))
    end
  end
end
