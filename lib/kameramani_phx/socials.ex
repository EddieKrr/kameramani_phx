defmodule KameramaniPhx.Socials do
  @moduledoc """
  The Socials context.
  """

  import Ecto.Query, warn: false
  alias KameramaniPhx.Repo
  alias KameramaniPhx.Accounts.User
  alias KameramaniPhx.Socials.SocialAccount

  @doc """
  Returns the list of social_accounts.

  ## Examples

      iex> list_social_accounts()
      [%SocialAccount{}, ...]

  """
  def list_social_accounts(username) do
    Repo.all(from sa in SocialAccount, where: sa.username == ^username)
  end

  # list trhe user social accounts
  def list_user_socials(%User{} = user) do
    Repo.all(from sa in SocialAccount, where: sa.user_id == ^user.id)
  end

  @doc """
  Gets a single social_account.

  Raises `Ecto.NoResultsError` if the Social account does not exist.

  ## Examples

      iex> get_social_account!(123)
      %SocialAccount{}

      iex> get_social_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_social_account!(id), do: Repo.get!(SocialAccount, id)

  @doc """
  Creates a social_account.

  ## Examples

      iex> create_social_account(%{field: value})
      {:ok, %SocialAccount{}}

      iex> create_social_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_social_account(%User{} = user, attrs) do
    user
    |> Ecto.build_assoc(:social_accounts)
    |> SocialAccount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a social_account.

  ## Examples

      iex> update_social_account(social_account, %{field: new_value})
      {:ok, %SocialAccount{}}

      iex> update_social_account(social_account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_social_account(%SocialAccount{} = social_account, attrs) do
    social_account
    |> SocialAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a social_account.

  ## Examples

      iex> delete_social_account(social_account)
      {:ok, %SocialAccount{}}

      iex> delete_social_account(social_account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_social_account(%SocialAccount{} = social_account) do
    Repo.delete(social_account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking social_account changes.

  ## Examples

      iex> change_social_account(social_account)
      %Ecto.Changeset{data: %SocialAccount{}}

  """
  def change_social_account(%SocialAccount{} = social_account, attrs \\ %{}) do
    SocialAccount.changeset(social_account, attrs)
  end
end
