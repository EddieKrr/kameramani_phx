defmodule KameramaniPhx.Chat.LiveChat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "live_chats" do
    field :body, :string
    field :room_id, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs, user_user) do
    message
    |> cast(attrs, [:body, :room_id])
    |> validate_required([:body, :room_id])
    |> put_change(:user_id, user_user.user.id)
  end
end
