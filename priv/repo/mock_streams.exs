# Only start the Repo to avoid port conflicts with the running server
KameramaniPhx.Repo.start_link()

alias KameramaniPhx.Repo
alias KameramaniPhx.Accounts.User
alias KameramaniPhx.Streaming
alias KameramaniPhx.Streaming.Stream
import Ecto.Query

IO.puts("🚀 Generating mock live streams (Direct Repo Access)...")

# Get existing users from database
usernames = ["tester", "GrandpaMax", "Kakarot", "Neo", "Ken"]
users = Repo.all(from u in User, where: u.username in ^usernames)

mock_data = [
  {"Epic Gaming Session", "Gaming"},
  {"Coding the Matrix", "Software Development"},
  {"Just Chatting and Chill", "Just Chatting"},
  {"Late Night Lo-Fi Beats", "Music"},
  {"Digital Art Speedrun", "Art"}
]

# Zip users with mock data and create/update streams
Enum.zip(users, mock_data)
|> Enum.each(fn {user, {title, category}} ->
  # Create a stream if they don't have one, or update existing
  stream = case Streaming.get_stream_for_user(user.id) do
    nil ->
      %Stream{user_id: user.id, stream_key: "mock_#{user.username}"}
    s ->
      s
  end

  stream
  |> Ecto.Changeset.change(%{
    title: title,
    category: category,
    is_live: true
  })
  |> Repo.insert_or_update!()

  IO.puts("✨ Stream live for #{user.username}: #{title}")
end)

IO.puts("✅ 5 Mock streams are now live! Refresh the landing page.")
