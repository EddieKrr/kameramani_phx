defmodule KameramaniPhx.Streaming do
  @moduledoc """
  The Streaming context.
  """

  import Ecto.Query, warn: false
  alias KameramaniPhx.Repo

  alias KameramaniPhx.Streaming.Stream

  def get_active_stream_for_user(user_id) do
    case Repo.all(from s in Stream, where: s.user_id == ^user_id) do
      [] -> nil
      [stream | _rest] -> stream
    end
  end

  def get_stream_by_key(stream_key) do
    Repo.get_by(Stream, stream_key: stream_key)
  end

  @doc """
  Returns the list of streams.

  ## Examples

      iex> list_streams()
      [%Stream{}, ...]

  """
  def list_streams do
    Repo.all(Stream)
  end

  @doc """
  Gets a single stream.

  Raises `Ecto.NoResultsError` if the Stream does not exist.

  ## Examples

      iex> get_stream!(123)
      %Stream{}

      iex> get_stream!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stream!(id), do: Repo.get!(Stream, id)

  # get the stream_key for a given stream id

  @doc """
  Creates a stream.

  ## Examples

      iex> create_stream(%{field: value})
      {:ok, %Stream{}}

      iex> create_stream(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stream(attrs \\ %{}) do
    # Extract the user_id (UUID) from the attributes
    user_id = attrs[:user_id] || attrs["user_id"]

    # If we have a user_id, add the generated stream_key to the attributes
    attrs =
      if user_id do
        Map.put_new(attrs, "stream_key", generate_stream_key(user_id))
      else
        attrs
      end

    %Stream{}
    |> Stream.changeset(attrs)
    |> Repo.insert()
  end

  # get the stream_key for a given stream id
  def get_stream_key(stream_id) do
    case get_stream!(stream_id) do
      %Stream{stream_key: stream_key} -> stream_key
      _ -> nil
    end
  end

  def generate_stream_key(user_id) when is_binary(user_id) do
    secret = generate_random_secret(16)
    "live_km_#{user_id}_#{secret}"
  end

  defp generate_random_secret(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end

  # now gotta verify the stream key

  def verify_key("live_km_" <> rest) do
    uuid = String.slice(rest, 0, 36)
    secret = String.slice(rest, 37..-1//1)
    full_key = "live_km_#{uuid}_#{secret}"

    case Repo.get_by(Stream, user_id: uuid, stream_key: full_key) do
      %Stream{} -> {:ok, full_key}
      nil -> {:error, :invalid_key}
    end
  end

  # malformed keys Fakes
  def verify_key(_), do: {:error, :malformed_key}

  @doc """
  Updates a stream.

  ## Examples

      iex> update_stream(stream, %{field: new_value})
      {:ok, %Stream{}}

      iex> update_stream(stream, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stream(%Stream{} = stream, attrs) do
    stream
    |> Stream.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stream.

  ## Examples

      iex> delete_stream(stream)
      {:ok, %Stream{}}

      iex> delete_stream(stream)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stream(%Stream{} = stream) do
    Repo.delete(stream)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stream changes.

  ## Examples

      iex> change_stream(stream)
      %Ecto.Changeset{data: %Stream{}}

  """
  def change_stream(%Stream{} = stream, attrs \\ %{}) do
    Stream.changeset(stream, attrs)
  end
end
