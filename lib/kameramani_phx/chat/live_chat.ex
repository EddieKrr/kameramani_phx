defmodule KameramaniPhx.Chat.LiveChat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "live_chats" do
    field :body, :string
    
    belongs_to :stream, KameramaniPhx.Streaming.Stream
    belongs_to :user, KameramaniPhx.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :stream_id, :user_id])
    |> validate_required([:body, :stream_id, :user_id])
  end
end
