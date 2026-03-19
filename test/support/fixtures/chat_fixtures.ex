defmodule KameramaniPhx.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Chat` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(user, stream_id, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "some body",
        user_id: user.id,
        stream_id: stream_id
      })

    {:ok, message} = KameramaniPhx.Chat.create_stream_message(attrs)
    message
  end
end
