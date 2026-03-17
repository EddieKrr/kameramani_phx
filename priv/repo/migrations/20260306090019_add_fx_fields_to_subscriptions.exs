defmodule KameramaniPhx.Repo.Migrations.AddFxFieldsToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :amount_kes, :decimal, precision: 12, scale: 2, null: false, default: 0
      add :fx_rate, :decimal, precision: 12, scale: 6, null: false, default: 0
      add :currency, :string, null: false, default: "KES"
      add :fx_fetched_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

    execute """
    UPDATE subscriptions
    SET amount_kes = ROUND(amount * 130, 2),
        fx_rate = 130,
        currency = 'KES',
        fx_fetched_at = NOW()
    """

    create constraint(:subscriptions, :subscriptions_amount_kes_must_be_positive,
             check: "amount_kes > 0"
           )

    create constraint(:subscriptions, :subscriptions_fx_rate_must_be_positive,
             check: "fx_rate > 0"
           )

    alter table(:subscriptions) do
      modify :amount_kes, :decimal, precision: 12, scale: 2, null: false, default: nil
      modify :fx_rate, :decimal, precision: 12, scale: 6, null: false, default: nil
      modify :fx_fetched_at, :utc_datetime, null: false, default: nil
    end
  end
end
