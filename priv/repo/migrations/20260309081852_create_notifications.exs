defmodule KameramaniPhx.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :entity_type, :string
      add :entity_id, :binary_id
      add :metadata, :map, null: false, default: %{}
      add :read_at, :utc_datetime
      add :recipient_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:recipient_id])
    create index(:notifications, [:recipient_id, :read_at])
    create index(:notifications, [:recipient_id, :inserted_at])
    create index(:notifications, [:entity_type, :entity_id])
  end
end
