defmodule KameramaniPhx.Repo.Migrations.DropMessagesTable do
  use Ecto.Migration

  def change do
    # This allows you to "undo" the drop if you change your mind
    create table(:live_chats, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body, :text
      add :room_id, :string
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      timestamps()
    end
  end
end
