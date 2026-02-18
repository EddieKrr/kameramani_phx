defmodule KameramaniPhx.Chat.LiveChat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "live_chats" do
    field :body, :string
    # References UUID stream.id
    belongs_to :stream, KameramaniPhx.Chat.Stream, type: :binary_id
    # User ID associated with message sender (bigint)
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs, user_user) do
    message
    # stream_id is UUID
    |> cast(attrs, [:body, :stream_id])
    |> validate_required([:body, :stream_id])
    # user_id is bigint
    |> put_change(:user_id, user_user.user.id)
  end
end
