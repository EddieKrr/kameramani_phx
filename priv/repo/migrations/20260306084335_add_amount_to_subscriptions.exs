defmodule KameramaniPhx.Repo.Migrations.AddAmountToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :amount, :decimal, precision: 10, scale: 2, null: false, default: 0
    end

    execute """
    UPDATE subscriptions
    SET amount = CASE tier
      WHEN 1 THEN 1.99
      WHEN 3 THEN 5.37
      WHEN 6 THEN 10.15
      ELSE 0
    END
    """

    create constraint(:subscriptions, :subscriptions_tier_must_be_supported,
             check: "tier IN (1, 3, 6)"
           )

    create constraint(:subscriptions, :subscriptions_amount_must_be_positive, check: "amount > 0")

    alter table(:subscriptions) do
      modify :amount, :decimal, precision: 10, scale: 2, null: false, default: nil
    end
  end
end
