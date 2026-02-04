defmodule KameramaniPhx.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
    add :name, :string, null: false
    add :username, :string, null: false
    add :email, :string, required: true
    add :age, :integer, default: 0
    add :hashed_password, :string, null: false
    end
  end
end

