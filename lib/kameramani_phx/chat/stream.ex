defmodule KameramaniPhx.Chat.Stream do
  use Ecto.Schema
  import Ecto.Changeset

  schema "streams" do
    field :name, :string
    # Referencing bigint user.id
    belongs_to :user, KameramaniPhx.Accounts.User
    # Ecto defaults to integer primary key, so no @primary_key needed here unless customizing

    timestamps()
  end

  @doc false
  # User_scope added back
  def changeset(stream, attrs, user_scope) do
    stream
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
    # user_id is bigint
    |> put_change(:user_id, user_scope.user.id)
  end
end
