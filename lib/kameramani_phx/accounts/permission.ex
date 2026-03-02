defmodule KameramaniPhx.Accounts.Permission do

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "permissions" do
    field :slug, :string
    field :description, :string
    many_to_many :roles, KameramaniPhx.Accounts.Role, join_through: "role_permissions"
    timestamps()
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:slug, :description])
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end
end
