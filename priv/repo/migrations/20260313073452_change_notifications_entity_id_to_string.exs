defmodule KameramaniPhx.Repo.Migrations.ChangeNotificationsEntityIdToString do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      modify :entity_id, :string
    end
  end
end
