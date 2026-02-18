defmodule KameramaniPhx.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias KameramaniPhx.Repo

  alias KameramaniPhx.Chat.LiveChat, as: Message
  alias KameramaniPhx.Accounts.Scope
  # Removed Stream alias and related functions to separate concerns.


  @doc """
  Subscribes to userd notifications about any message changes.

  The broadcasted messages match the pattern:

    * {:created, %Message{}}
    * {:updated, %Message{}}
    * {:deleted, %Message{}}

  """
  def subscribe_messages(%Scope{} = user) do
    key = user.user.id

    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "user:#{key}:messages")
  end

  defp broadcast_message(%Scope{} = user, message) do
    key = user.user.id

    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "user:#{key}:messages", message)
  end

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages(user)
      [%Message{}, ...]

  """
  def list_messages(%Scope{} = user) do
    Repo.all_by(Message, user_id: user.user.id)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(user, 123)
      %Message{}

      iex> get_message!(user, 456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(%Scope{} = user, id) do
    Repo.get_by!(Message, id: id, user_id: user.user.id)
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(user, %{field: value})
      {:ok, %Message{}}

      iex> create_message(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(%Scope{} = user, attrs) do
    with {:ok, message = %Message{}} <-
           %Message{}
           |> Message.changeset(attrs, user)
           |> Repo.insert() do
      broadcast_message(user, {:created, message})
      {:ok, message}
    end
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(user, message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(user, message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Scope{} = user, %Message{} = message, attrs) do
    true = message.user_id == user.user.id

    with {:ok, message = %Message{}} <-
           message
           |> Message.changeset(attrs, user)
           |> Repo.update() do
      broadcast_message(user, {:updated, message})
      {:ok, message}
    end
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(user, message)
      {:ok, %Message{}}

      iex> delete_message(user, message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Scope{} = user, %Message{} = message) do
    true = message.user_id == user.user.id

    with {:ok, message = %Message{}} <-
           Repo.delete(message) do
      broadcast_message(user, {:deleted, message})
      {:ok, message}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(user, message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Scope{} = user, %Message{} = message, attrs \\ %{}) do
    true = message.user_id == user.user.id

    Message.changeset(message, attrs, user)
  end
end
