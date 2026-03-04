alias KameramaniPhx.Repo
alias KameramaniPhx.Content.Category
alias KameramaniPhx.Accounts.{User, Role, Permission}
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

IO.puts("Inserting categories into the database...")

Enum.each(categories, fn cat ->
  # upsert (insert or do nothing if it exists)
  case Repo.get_by(Category, slug: cat.slug) do
    nil ->
      Repo.insert!(%Category{
        id: Ecto.UUID.generate(),
        name: cat.name,
        slug: cat.slug,
        thumbnail_url: cat.thumbnail_url
      })

      IO.puts("Created category: #{cat.name}")

    _ ->
      IO.puts("Category already exists: #{cat.name}")
  end
end)

IO.puts("Inserting users into the database...")

users = [
  %{
    name: "Cubey",
    username: "cubey",
    email: "cubey@test.com",
    password: "cubey123",
    age: 25,
    confirmed_at: DateTime.utc_now()
  },
  %{
    name: "Tester",
    username: "tester",
    email: "tester@test.com",
    password: "tester123",
    age: 30,
    confirmed_at: DateTime.utc_now()
  },
  %{
    name: "Max",
    username: "max",
    email: "max@test.com",
    password: "max123",
    age: 22,
    confirmed_at: DateTime.utc_now()
  },
  %{
    name: "Gwen",
    username: "gwen",
    email: "gwen@test.com",
    password: "gwen123",
    age: 28,
    confirmed_at: DateTime.utc_now()
  },
  %{
    name: "Ben",
    username: "ben",
    email: "ben@test.com",
    password: "ben123",
    age: 35,
    confirmed_at: DateTime.utc_now()
  }
]

Enum.each(users, fn user_attrs ->
  # ensure user_id is generated from UUID
  user_attrs = Map.put(user_attrs, :id, Ecto.UUID.generate())
  # You might want to get category ID to assign a default category
  # category = KameramaniPhx.Content.get_category_by_slug("gaming")

  case KameramaniPhx.Accounts.register_user(user_attrs) do
    {:ok, user} ->
      IO.puts("Created user: #{user.username}")

    {:error, %Ecto.Changeset{} = changeset} ->
      IO.puts("Failed to create user #{user_attrs.username}: #{inspect(changeset.errors)}")
  end
end)

roles_to_create = ["admin", "moderator", "user"]

for role_name <- roles_to_create do
  case Repo.get_by(Role, name: role_name) do
    nil ->
      {:ok, _} = Repo.insert(%Role{name: role_name})
      IO.puts("🔹 Created role: #{role_name}")

    _ ->
      IO.puts("🔹 Role '#{role_name}' already exists. Skipping.")
  end
end

IO.puts("✅ Roles table populated.")

# 2. Define the Permissions Dictionary
permissions_data = [
  %Permission{slug: "delete_saved_streams", description: "Delete saved streams"},
  %Permission{slug: "stream-edit", description: "Edit existing streams"},
  %Permission{slug: "stream-delete", description: "Delete streams"},
  %Permission{slug: "user-ban", description: "Ban users"},
  %Permission{slug: "user-mute", description: "Mute users"},
  %Permission{slug: "user-warning", description: "Warn users"},
  %Permission{slug: "manage_users", description: "Manage user accounts"},
  %Permission{slug: "manage_streams", description: "Manage streams"},
  %Permission{slug: "moderate_content", description: "Moderate content"},
  %Permission{slug: "view_analytics", description: "View analytics"},
  %Permission{slug: "manage_roles", description: "Manage roles and permissions"},
  %Permission{slug: "access_sales_dashboard", description: "Access sales dashboard"},
  %Permission{slug: "manage_conversations", description: "Manage conversations"}
]

permission_map =
  Enum.reduce(permissions_data, %{}, fn data, acc ->
    perm =
      case Repo.get_by(Permission, slug: data.slug) do
        nil -> Repo.insert!(data)
        existing -> existing
      end

    Map.put(acc, data.slug, perm)
  end)

IO.puts("✅ Permissions table populated.")

assign_perms = fn role_name, slugs ->
  role = Repo.get_by(Role, name: role_name) |> Repo.preload(:permissions)

  if role do
    perms_to_add = Enum.map(slugs, fn s -> Map.get(permission_map, s) end)

    role
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:permissions, perms_to_add)
    |> Repo.update!()

    IO.puts("🔹 Assigned [#{Enum.join(slugs, ", ")}] to role: #{role_name}")
  else
    IO.puts("⚠️ Role '#{role_name}' not found. Skipping.")
  end
end

assign_perms.("admin", [
  "delete_saved_streams",
  "stream-edit",
  "stream-delete",
  "user-ban",
  "user-mute",
  "user-warning",
  "manage_users",
  "manage_streams",
  "moderate_content",
  "view_analytics",
  "manage_roles",
  "access_sales_dashboard",
  "manage_conversations"
])

assign_perms.("moderator", ["stream-edit", "stream-delete", "user-warning"])
assign_perms.("user", ["delete_saved_streams", "stream-edit"])

IO.puts("Done!")
