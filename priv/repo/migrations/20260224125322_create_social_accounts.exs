defmodule KameramaniPhx.Repo.Migrations.CreateSocialAccounts do
  use Ecto.Migration

  def change do
    create table(:social_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :platform, :string
      add :url, :string
      add :username, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:social_accounts, [:user_id])
  end
end
