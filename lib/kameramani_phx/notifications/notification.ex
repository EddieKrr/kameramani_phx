defmodule KameramaniPhx.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @types [
    :stream_went_live,
    :new_follower,
    :new_subscription,
    :verification_submitted,
    :verification_approved,
    :verification_rejected
  ]

  schema "notifications" do
    field :type, Ecto.Enum, values: @types
    field :entity_type, :string
    field :entity_id, :string
    field :metadata, :map, default: %{}
    field :read_at, :utc_datetime

    belongs_to :recipient, KameramaniPhx.Accounts.User
    belongs_to :actor, KameramaniPhx.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :type,
      :entity_type,
      :entity_id,
      :metadata,
      :read_at,
      :recipient_id,
      :actor_id
    ])
    |> validate_required([:type, :recipient_id])
  end
end
