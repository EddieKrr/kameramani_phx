defmodule KameramaniPhx.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

 def change do
  alter table(:users) do
    add :bio, :text
    add :profile_picture, :string, default: "https://ui-avatars.com/api/?background=random"
  end
end
end
