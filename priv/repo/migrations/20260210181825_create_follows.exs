defmodule KameramaniPhx.Repo.Migrations.CreateFollows do
  use Ecto.Migration

 def change do
  create table(:follows) do
    add :follower_id, references(:users, on_delete: :delete_all), null: false
    add :followed_id, references(:users, on_delete: :delete_all), null: false
    timestamps()
  end

  # This index prevents someone from following the same person twice
  create unique_index(:follows, [:follower_id, :followed_id])
  create index(:follows, [:follower_id])
  create index(:follows, [:followed_id])
end
end
