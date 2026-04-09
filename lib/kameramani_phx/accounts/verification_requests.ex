defmodule KameramaniPhx.Accounts.VerificationRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "verification_requests" do
    field :status, :string, default: "pending"
    field :social_links, {:array, :string}, default: []
    field :admin_notes, :string

    belongs_to :user, KameramaniPhx.Accounts.User, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [:status, :social_links, :admin_notes, :user_id])
    |> validate_required([:status, :user_id])
    |> validate_inclusion(:status, ["pending", "approved", "rejected"])
  end
end
