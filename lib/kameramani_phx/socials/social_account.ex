defmodule KameramaniPhx.Socials.SocialAccount do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  import Ecto.Changeset

  schema "social_accounts" do
    field :platform, :string
    field :url, :string
    field :username, :string
    belongs_to :user, KameramaniPhx.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(social_account, attrs) do
    social_account
    |> cast(attrs, [:platform, :url, :username])
    |> validate_required([:platform, :url, :username])
  end
end
