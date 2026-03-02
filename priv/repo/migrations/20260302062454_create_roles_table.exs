defmodule KameramaniPhx.Repo.Migrations.CreateRolesTable do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])

    create table(:permissions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :slug, :string, null: false
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:slug])

    create table(:user_roles, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :role_id, references(:roles, type: :uuid, on_delete: :delete_all), null: false
    end

    create index(:user_roles, [:user_id])
    create index(:user_roles, [:role_id])
    create unique_index(:user_roles, [:user_id, :role_id])

    create table(:role_permissions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :role_id, references(:roles, type: :uuid, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, type: :uuid, on_delete: :delete_all), null: false
    end

    create index(:role_permissions, [:role_id])
    create index(:role_permissions, [:permission_id])
    create unique_index(:role_permissions, [:role_id, :permission_id])
  end
end
