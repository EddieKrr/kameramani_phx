defmodule KameramaniPhx.Repo.Migrations.CreateStreams do
  use Ecto.Migration

  def change do
    create table(:streams, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, default: "New Stream", null: false
      add :stream_key, :string, null: false
      add :is_live, :boolean, default: false, null: false
      add :tags, {:array, :string}, default: []
      add :user_id, references(:users, type: :uuid, on_delete: :nothing), null: false
      add :category_id, references(:categories, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:streams, [:stream_key])
    create index(:streams, [:user_id])
    create index(:streams, [:category_id])
  end
end
