defmodule KameramaniPhx.Accounts.Follow do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "follows" do
    field :follower_id, :binary_id
    field :followed_id, :binary_id

    timestamps(type: :utc_datetime)
  end
end
