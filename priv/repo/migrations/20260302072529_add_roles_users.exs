defmodule KameramaniPhx.Repo.Migrations.AddRolesUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :roles, {:array, :string}, default: []
    end
  end
end
