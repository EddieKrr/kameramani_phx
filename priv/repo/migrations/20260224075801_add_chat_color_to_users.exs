defmodule KameramaniPhx.Repo.Migrations.AddChatColorToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :chat_color, :string, default: "#6366f1"
    end

    # Randomize colors for existing users
    execute """
    UPDATE users SET chat_color = '#' || 
    LPAD(TRUNC(RANDOM() * 255)::INT::TEXT, 2, '0') || 
    LPAD(TRUNC(RANDOM() * 255)::INT::TEXT, 2, '0') || 
    LPAD(TRUNC(RANDOM() * 255)::INT::TEXT, 2, '0')
    """
  end
end
