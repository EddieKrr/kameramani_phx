defmodule KameramaniPhx.Repo.Migrations.FixUserChatColors do
  use Ecto.Migration

  def up do
    # Define our curated colors
    colors = ~w(#3b82f6 #ef4444 #f97316 #eab308 #ec4899 #a855f7 #22c55e #84cc16)
    
    # Update existing users by rotating through the color list based on their ID
    # This ensures a deterministic but "random" distribution
    for {color, index} <- Enum.with_index(colors) do
      execute "UPDATE users SET chat_color = '#{color}' WHERE (hashtext(id::text) % 8) = #{index}"
    end
    
    # Catch any remaining ones (though hashtext % 8 covers all possibilities)
    execute "UPDATE users SET chat_color = '#{List.first(colors)}' WHERE chat_color IS NULL"
  end

  def down do
    :ok
  end
end
