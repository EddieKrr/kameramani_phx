defmodule KameramaniPhx.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :tier, :integer
      add :status, :string
      add :expires_at, :utc_datetime
      add :subscriber_id, references(:users, type: :uuid, on_delete: :nothing)
      add :streamer_id, references(:users, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:subscriptions, [:subscriber_id])
    create index(:subscriptions, [:streamer_id])
    create unique_index(:subscriptions, [:subscriber_id, :streamer_id])
  end
end
