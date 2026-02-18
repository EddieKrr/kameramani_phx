defmodule KameramaniPhx.Streaming.Stream do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  import Ecto.Changeset

  schema "streams" do
    field :title, :string
    field :stream_key, :string
    field :is_live, :boolean, default: false
    field :tags, {:array, :string}
    belongs_to :user, KameramaniPhx.Accounts.User, type: :binary_id
    belongs_to :category, KameramaniPhx.Content.Category, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(stream, attrs) do
    stream
    |> cast(attrs, [:title, :stream_key, :is_live, :tags, :user_id, :category_id])
    |> validate_required([:title, :stream_key, :is_live, :tags, :user_id])
    |> unique_constraint(:stream_key)
  end
end
