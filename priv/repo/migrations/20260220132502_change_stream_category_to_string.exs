defmodule KameramaniPhx.Repo.Migrations.ChangeStreamCategoryToString do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      remove :category_id
      add :category, :string, default: "Just Chatting"
    end
  end
end
