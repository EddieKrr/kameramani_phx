defmodule KameramaniPhx.Users do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :username, :string
    field :email, :string
    field :age, :integer, default: 0
    field :password, :integer
    field :bio, :string
    field :profile_picture, :string
    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :username, :email, :age, :bio, :profile_picture])
    |> validate_required([:name, :age])
  end
end
