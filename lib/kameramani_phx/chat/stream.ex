# defmodule KameramaniPhx.Chat.Stream do
#   use Ecto.Schema
#   import Ecto.Changeset

#   schema "streams" do
#     field :name, :string
#     belongs_to :user, KameramaniPhx.Accounts.User # Referencing bigint user.id
#     # Ecto defaults to integer primary key, so no @primary_key needed here unless customizing

#     timestamps()
#   end

#   @doc false
#   def changeset(stream, attrs, user_scope) do # User_scope added back
#     stream
#     |> cast(attrs, [:name])
#     |> validate_required([:name])
#     |> unique_constraint(:name)
#     |> put_change(:user_id, user_scope.user.id) # user_id is bigint
#   end
# end
