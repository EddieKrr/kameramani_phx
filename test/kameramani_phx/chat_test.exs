defmodule KameramaniPhx.ChatTest do
  use KameramaniPhx.DataCase

  alias KameramaniPhx.Chat

  describe "messages" do
    alias KameramaniPhx.Chat.Message

    import KameramaniPhx.AccountsFixtures, only: [user_user_fixture: 0]
    import KameramaniPhx.ChatFixtures

    @invalid_attrs %{body: nil, room_id: nil}

    test "list_messages/1 returns all userd messages" do
      user = user_user_fixture()
      other_user = user_user_fixture()
      message = message_fixture(user)
      other_message = message_fixture(other_user)
      assert Chat.list_messages(user) == [message]
      assert Chat.list_messages(other_user) == [other_message]
    end

    test "get_message!/2 returns the message with given id" do
      user = user_user_fixture()
      message = message_fixture(user)
      other_user = user_user_fixture()
      assert Chat.get_message!(user, message.id) == message
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(other_user, message.id) end
    end

    test "create_message/2 with valid data creates a message" do
      valid_attrs = %{body: "some body", room_id: "some room_id"}
      user = user_user_fixture()

      assert {:ok, %Message{} = message} = Chat.create_message(user, valid_attrs)
      assert message.body == "some body"
      assert message.room_id == "some room_id"
      assert message.user_id == user.user.id
    end

    test "create_message/2 with invalid data returns error changeset" do
      user = user_user_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.create_message(user, @invalid_attrs)
    end

    test "update_message/3 with valid data updates the message" do
      user = user_user_fixture()
      message = message_fixture(user)
      update_attrs = %{body: "some updated body", room_id: "some updated room_id"}

      assert {:ok, %Message{} = message} = Chat.update_message(user, message, update_attrs)
      assert message.body == "some updated body"
      assert message.room_id == "some updated room_id"
    end

    test "update_message/3 with invalid user raises" do
      user = user_user_fixture()
      other_user = user_user_fixture()
      message = message_fixture(user)

      assert_raise MatchError, fn ->
        Chat.update_message(other_user, message, %{})
      end
    end

    test "update_message/3 with invalid data returns error changeset" do
      user = user_user_fixture()
      message = message_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Chat.update_message(user, message, @invalid_attrs)
      assert message == Chat.get_message!(user, message.id)
    end

    test "delete_message/2 deletes the message" do
      user = user_user_fixture()
      message = message_fixture(user)
      assert {:ok, %Message{}} = Chat.delete_message(user, message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(user, message.id) end
    end

    test "delete_message/2 with invalid user raises" do
      user = user_user_fixture()
      other_user = user_user_fixture()
      message = message_fixture(user)
      assert_raise MatchError, fn -> Chat.delete_message(other_user, message) end
    end

    test "change_message/2 returns a message changeset" do
      user = user_user_fixture()
      message = message_fixture(user)
      assert %Ecto.Changeset{} = Chat.change_message(user, message)
    end
  end
end
