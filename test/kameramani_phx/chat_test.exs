defmodule KameramaniPhx.ChatTest do
  use KameramaniPhx.DataCase

  alias KameramaniPhx.Chat

  describe "messages" do
    alias KameramaniPhx.Chat.LiveChat, as: Message

    import KameramaniPhx.AccountsFixtures, only: [user_user_fixture: 0]
    import KameramaniPhx.StreamingFixtures
    import KameramaniPhx.ChatFixtures

    @invalid_attrs %{body: nil, stream_id: nil, user_id: nil}

    defp strip_preloads(message) when is_list(message) do
      Enum.map(message, &strip_preloads/1)
    end

    defp strip_preloads(%Message{} = message) do
      %{message | user: %Ecto.Association.NotLoaded{}, stream: %Ecto.Association.NotLoaded{}}
    end

    test "list_messages/1 returns all userd messages" do
      user_scope = user_user_fixture()
      other_user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)
      other_message = message_fixture(other_user_scope.user, stream.id)

      assert strip_preloads(Chat.list_messages(user_scope)) == strip_preloads([message])

      assert strip_preloads(Chat.list_messages(other_user_scope)) ==
               strip_preloads([other_message])
    end

    test "get_message!/2 returns the message with given id" do
      user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)
      other_user_scope = user_user_fixture()

      assert strip_preloads(Chat.get_message!(user_scope, message.id)) == strip_preloads(message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(other_user_scope, message.id) end
    end

    test "create_stream_message/1 with valid data creates a message" do
      user_scope = user_user_fixture()
      user = user_scope.user
      stream = stream_fixture(%{user_id: user.id})
      valid_attrs = %{body: "some body", stream_id: stream.id, user_id: user.id}

      assert {:ok, %Message{} = message} = Chat.create_stream_message(valid_attrs)
      assert message.body == "some body"
      assert message.stream_id == stream.id
      assert message.user_id == user.id
    end

    test "create_stream_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_stream_message(@invalid_attrs)
    end

    test "update_message/3 with valid data updates the message" do
      user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)
      update_attrs = %{body: "some updated body"}

      assert {:ok, %Message{} = message} = Chat.update_message(user_scope, message, update_attrs)
      assert message.body == "some updated body"
    end

    test "update_message/3 with invalid user raises" do
      user_scope = user_user_fixture()
      other_user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)

      assert_raise MatchError, fn ->
        Chat.update_message(other_user_scope, message, %{})
      end
    end

    test "update_message/3 with invalid data returns error changeset" do
      user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)
      assert {:error, %Ecto.Changeset{}} = Chat.update_message(user_scope, message, %{body: nil})
      assert strip_preloads(message) == strip_preloads(Chat.get_message!(user_scope, message.id))
    end

    test "delete_message/2 deletes the message" do
      user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)
      assert {:ok, %Message{}} = Chat.delete_message(user_scope, message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(user_scope, message.id) end
    end

    test "delete_message/2 with invalid user raises" do
      user_scope = user_user_fixture()
      other_user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)
      assert_raise MatchError, fn -> Chat.delete_message(other_user_scope, message) end
    end

    test "change_message/2 returns a message changeset" do
      user_scope = user_user_fixture()
      stream = stream_fixture(%{user_id: user_scope.user.id})
      message = message_fixture(user_scope.user, stream.id)
      assert %Ecto.Changeset{} = Chat.change_message(user_scope, message)
    end
  end
end
