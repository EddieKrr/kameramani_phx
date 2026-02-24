defmodule KameramaniPhx.Repo.Migrations.AddCascadeDeleteToLiveChatsStreamId do
  use Ecto.Migration

  def up do
    # Drop the existing constraint
    drop constraint(:live_chats, "live_chats_stream_id_fkey")

    # Add the new constraint with cascade delete
    alter table(:live_chats) do
      modify :stream_id, references(:streams, type: :uuid, on_delete: :delete_all)
    end
  end

  def down do
    # Revert to default behavior if needed
    drop constraint(:live_chats, "live_chats_stream_id_fkey")

    alter table(:live_chats) do
      modify :stream_id, references(:streams, type: :uuid, on_delete: :nothing)
    end
  end
end
