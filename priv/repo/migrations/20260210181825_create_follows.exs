defmodule KameramaniPhx.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :follower_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :followed_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      timestamps()
    end

    # This index prevents someone from following the same person twice
    create unique_index(:follows, [:follower_id, :followed_id])
    create index(:follows, [:follower_id])
    create index(:follows, [:followed_id])
  end
end
