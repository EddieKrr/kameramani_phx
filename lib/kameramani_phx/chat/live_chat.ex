defmodule KameramaniPhx.Chat.LiveChat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "live_chats" do
    field :body, :string
    belongs_to :stream, KameramaniPhx.Chat.Stream, type: :binary_id # References UUID stream.id
    field :user_id, :id # User ID associated with message sender (bigint)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs, user_user) do
    message
    |> cast(attrs, [:body, :stream_id]) # stream_id is UUID
    |> validate_required([:body, :stream_id])
    |> put_change(:user_id, user_user.user.id) # user_id is bigint
  end
end
