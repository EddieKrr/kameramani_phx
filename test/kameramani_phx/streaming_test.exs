defmodule KameramaniPhx.StreamingTest do
  use KameramaniPhx.DataCase

  alias KameramaniPhx.Streaming

  describe "streams" do
    alias KameramaniPhx.Streaming.Stream

    import KameramaniPhx.StreamingFixtures
    import KameramaniPhx.AccountsFixtures, only: [user_user_fixture: 0]

    @invalid_attrs %{title: nil, stream_key: nil, is_live: nil, tags: nil}

    test "list_streams/0 returns all streams" do
      stream = stream_fixture() |> Repo.preload([:user])
      streams = Streaming.list_streams() |> Enum.map(&Repo.preload(&1, [:user]))
      assert Enum.any?(streams, fn s -> s.id == stream.id end)
    end

    test "get_stream!/1 returns the stream with given id" do
      stream = stream_fixture()
      assert Streaming.get_stream!(stream.id) == stream
    end

    test "create_stream/1 with valid data creates a stream" do
      user_scope = user_user_fixture()
      user = user_scope.user

      valid_attrs = %{
        title: "some title",
        stream_key: "some stream_key",
        is_live: true,
        tags: ["option1", "option2"],
        user_id: user.id
      }

      assert {:ok, %Stream{} = stream} = Streaming.create_stream(valid_attrs)
      assert stream.title == "some title"
      assert stream.stream_key == "some stream_key"
      assert stream.is_live == true
      assert stream.tags == ["option1", "option2"]
      assert stream.user_id == user.id
    end

    test "create_stream/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Streaming.create_stream(@invalid_attrs)
    end

    test "update_stream/2 with valid data updates the stream" do
      stream = stream_fixture()

      update_attrs = %{
        title: "some updated title",
        stream_key: "some updated stream_key",
        is_live: false,
        tags: ["option1"]
      }

      assert {:ok, %Stream{} = stream} = Streaming.update_stream(stream, update_attrs)
      assert stream.title == "some updated title"
      assert stream.stream_key == "some updated stream_key"
      assert stream.is_live == false
      assert stream.tags == ["option1"]
    end

    test "update_stream/2 with invalid data returns error changeset" do
      stream = stream_fixture()
      assert {:error, %Ecto.Changeset{}} = Streaming.update_stream(stream, @invalid_attrs)
      assert stream == Streaming.get_stream!(stream.id)
    end

    test "delete_stream/1 deletes the stream" do
      stream = stream_fixture()
      assert {:ok, %Stream{}} = Streaming.delete_stream(stream)
      assert_raise Ecto.NoResultsError, fn -> Streaming.get_stream!(stream.id) end
    end

    test "change_stream/1 returns a stream changeset" do
      stream = stream_fixture()
      assert %Ecto.Changeset{} = Streaming.change_stream(stream)
    end
  end
end
