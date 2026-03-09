defmodule KameramaniPhx.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "subscriptions" do
    field :tier, :integer
    field :amount_usd, :decimal, source: :amount
    field :amount_kes, :decimal
    field :fx_rate, :decimal
    field :currency, :string, default: "KES"
    field :fx_fetched_at, :utc_datetime
    field :status, :string, default: "active"
    field :expires_at, :utc_datetime

    belongs_to :subscriber, KameramaniPhx.Accounts.User
    belongs_to :streamer, KameramaniPhx.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :tier,
      :amount_usd,
      :amount_kes,
      :fx_rate,
      :currency,
      :fx_fetched_at,
      :status,
      :expires_at,
      :subscriber_id,
      :streamer_id
    ])
    |> validate_required([
      :tier,
      :amount_usd,
      :amount_kes,
      :fx_rate,
      :currency,
      :fx_fetched_at,
      :status,
      :expires_at,
      :subscriber_id,
      :streamer_id
    ])
    |> validate_inclusion(:tier, [1, 3, 6])
    |> validate_number(:amount_usd, greater_than: 0)
    |> validate_number(:amount_kes, greater_than: 0)
    |> validate_number(:fx_rate, greater_than: 0)
    |> validate_inclusion(:currency, ["KES"])
    |> unique_constraint([:subscriber_id, :streamer_id],
      name: :subscriptions_subscriber_id_streamer_id_index
    )
  end
end
