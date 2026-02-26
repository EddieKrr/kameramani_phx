defmodule KameramaniPhx.Repo.Migrations.AddVodFields do
  use Ecto.Migration

  def change do
    alter table("streams") do
      add :duration_seconds, :integer, [null: true]
      add :storage_path, :string, [null: true]
      add :vod_play_count, :integer, [null: true]
    end
  end
end
