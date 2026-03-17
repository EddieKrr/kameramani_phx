defmodule KameramaniPhx.Repo.Migrations.AddUniqueIndexToStreamsUserId do
  use Ecto.Migration

  def up do
    # Remove duplicates before adding the unique index
    execute """
    DELETE FROM streams
    WHERE id NOT IN (
      SELECT id FROM (
        SELECT DISTINCT ON (user_id) id
        FROM streams
        ORDER BY user_id, updated_at DESC
      ) AS recent_streams
    )
    """

    # Drop existing non-unique index if it exists
    drop_if_exists index(:streams, [:user_id])

    # Create unique index
    create unique_index(:streams, [:user_id])
  end

  def down do
    drop index(:streams, [:user_id])
    create index(:streams, [:user_id])
  end
end
