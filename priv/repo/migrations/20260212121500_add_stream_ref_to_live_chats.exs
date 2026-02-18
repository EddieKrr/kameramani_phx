defmodule KameramaniPhx.Repo.Migrations.AddStreamRefToLiveChats do
  use Ecto.Migration

  def up do
    alter table(:live_chats) do
      add :stream_id, references(:streams, type: :uuid), null: true
      remove :room_id
    end
  end

  def down do
    alter table(:live_chats) do
      add :room_id, :string, null: true # Add back as nullable since original was likely nullable
      remove :stream_id
    end
  end
end
