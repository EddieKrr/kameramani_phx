# Direct SQL update to avoid application dependency issues
KameramaniPhx.Repo.start_link()

alias KameramaniPhx.Repo

IO.puts("🧹 Forcing all streams offline (Direct SQL)...")

# This is the most reliable way to clear the 'is_live' flags
Ecto.Adapters.SQL.query!(Repo, "UPDATE streams SET is_live = false", [])

IO.puts("✅ Database updated successfully.")
