defmodule KameramaniPhx.Repo.Migrations.AddThumbnailUrlsToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :thumbnail_url, :string
    end
  end
end
