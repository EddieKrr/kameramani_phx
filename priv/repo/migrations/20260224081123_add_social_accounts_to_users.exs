defmodule KameramaniPhx.Repo.Migrations.AddSocialAccountsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :accounts, {:array, :map}, default: []
    end
  end
end
