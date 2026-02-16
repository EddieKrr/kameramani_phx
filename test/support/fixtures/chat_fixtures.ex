defmodule KameramaniPhx.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Chat` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "some body",
        room_id: "some room_id"
      })

    {:ok, message} = KameramaniPhx.Chat.create_message(user, attrs)
    message
  end
end
