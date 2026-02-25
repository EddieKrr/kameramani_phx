defmodule KameramaniPhx.Streaming.Stream do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  import Ecto.Changeset

  schema "streams" do
    field :title, :string
    field :stream_key, :string
    field :is_live, :boolean, default: false
    field :tags, {:array, :string}
    field :category, :string, default: "Just Chatting"
    belongs_to :user, KameramaniPhx.Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(stream, attrs) do
    stream
    |> cast(attrs, [:title, :stream_key, :is_live, :tags, :user_id, :category])
    |> validate_required([:title, :stream_key, :is_live, :tags, :user_id])
    |> unique_constraint(:stream_key)
    |> unique_constraint(:user_id)
    |> sanitize_tags()
  end


  defp sanitize_tags(changeset) do
  if tags = get_change(changeset, :tags) do
    # Trim whitespace from every tag in the list
    clean_tags = Enum.map(tags, &String.trim/1)
    put_change(changeset, :tags, clean_tags)
  else
    changeset
  end
end
end
