defmodule KameramaniPhx.Repo.Migrations.AddMobileNumberToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :mobile_number, :string
    end
  end
end
