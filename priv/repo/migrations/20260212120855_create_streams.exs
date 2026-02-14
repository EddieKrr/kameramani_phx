defmodule KameramaniPhx.Repo.Migrations.CreateStreams do
  use Ecto.Migration

  def change do
    create table(:streams, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:streams, [:name])
  end
end
