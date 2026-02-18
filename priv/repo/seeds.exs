alias KameramaniPhx.Repo
alias KameramaniPhx.Content.Category
alias KameramaniPhx.Accounts.User
import Ecto.UUID




categories = [
  %{name: "Just Chatting", slug: "just-chatting", thumbnail_url: "https://shorturl.at/cU8up"},
  %{name: "Software Development", slug: "software-dev", thumbnail_url: "https://bit.ly/40czhEW"},
  %{name: "Cybersecurity", slug: "cybersecurity", thumbnail_url: "https://bit.ly/4rzmZCs"},
  %{name: "Gaming", slug: "gaming", thumbnail_url: "https://shorturl.at/Ijyox"},
  %{name: "Music", slug: "music", thumbnail_url: "https://shorturl.at/Lsyvs"},
  %{name: "Art", slug: "art", thumbnail_url: "https://shorturl.at/SLycL"},
  %{name: "Talk Shows & Podcasts", slug: "talk-shows", thumbnail_url: "https://bit.ly/4aAUywS"},
  %{name: "Crypto & Finance", slug: "finance", thumbnail_url: "https://bit.ly/3OlYom6"},
  %{name: "ASMR", slug: "asmr", thumbnail_url: "https://shorturl.at/gNfFe"},
  %{name: "Retro", slug: "retro", thumbnail_url: "https://bit.ly/4qGAoHS"}
]

IO.puts "Inserting categories into the database..."

Enum.each(categories, fn cat ->
  # upsert (insert or do nothing if it exists)
  case Repo.get_by(Category, slug: cat.slug) do
    nil ->
      Repo.insert!(%Category{id: Ecto.UUID.generate(), name: cat.name, slug: cat.slug, thumbnail_url: cat.thumbnail_url})
      IO.puts "Created category: #{cat.name}"
    _ ->
      IO.puts "Category already exists: #{cat.name}"
  end
end)

IO.puts "Inserting users into the database..."

users = [
  %{name: "Cubey", username: "cubey", email: "cubey@test.com", password: "cubey123", age: 25, confirmed_at: DateTime.utc_now()},
  %{name: "Tester", username: "tester", email: "tester@test.com", password: "tester123", age: 30, confirmed_at: DateTime.utc_now()},
  %{name: "Max", username: "max", email: "max@test.com", password: "max123", age: 22, confirmed_at: DateTime.utc_now()},
  %{name: "Gwen", username: "gwen", email: "gwen@test.com", password: "gwen123", age: 28, confirmed_at: DateTime.utc_now()},
  %{name: "Ben", username: "ben", email: "ben@test.com", password: "ben123", age: 35, confirmed_at: DateTime.utc_now()}
]

Enum.each(users, fn user_attrs ->
  # ensure user_id is generated from UUID
  user_attrs = Map.put(user_attrs, :id, Ecto.UUID.generate())
  # You might want to get category ID to assign a default category
  # category = KameramaniPhx.Content.get_category_by_slug("gaming")

  case KameramaniPhx.Accounts.register_user(user_attrs) do
    {:ok, user} ->
      IO.puts "Created user: #{user.username}"
    {:error, %Ecto.Changeset{} = changeset} ->
      IO.puts "Failed to create user #{user_attrs.username}: #{inspect changeset.errors}"
  end
end)

IO.puts "Done!"
