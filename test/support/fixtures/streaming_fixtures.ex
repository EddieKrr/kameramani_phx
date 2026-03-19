defmodule KameramaniPhx.StreamingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Streaming` context.
  """

  @doc """
  Generate a unique stream stream_key.
  """
  def unique_stream_stream_key, do: "some stream_key#{System.unique_integer([:positive])}"

  @doc """
  Generate a stream.
  """
  def stream_fixture(attrs \\ %{}) do
    attrs =
      if Map.has_key?(attrs, :user_id) or Map.has_key?(attrs, "user_id") do
        attrs
      else
        user_or_scope = KameramaniPhx.AccountsFixtures.user_user_fixture()

        user_id =
          case user_or_scope do
            %KameramaniPhx.Accounts.Scope{user: user} -> user.id
            user -> user.id
          end

        Map.put(attrs, :user_id, user_id)
      end

    {:ok, stream} =
      attrs
      |> Enum.into(%{
        is_live: true,
        stream_key: unique_stream_stream_key(),
        tags: ["option1", "option2"],
        title: "some title"
      })
      |> KameramaniPhx.Streaming.create_stream()

    stream
  end
end

defmodule KameramaniPhx.StreamingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Streaming` context.
  """

  @doc """
  Generate a unique stream stream_key.
  """
  def unique_stream_stream_key, do: "some stream_key#{System.unique_integer([:positive])}"

  @doc """
  Generate a stream.
  """
  def stream_fixture(attrs \\ %{}) do
    {:ok, stream} =
      attrs
      |> Enum.into(%{
        is_live: true,
        stream_key: unique_stream_stream_key(),
        tags: ["option1", "option2"],
        title: "some title"
      })
      |> KameramaniPhx.Streaming.create_stream()

    stream
  end
end
