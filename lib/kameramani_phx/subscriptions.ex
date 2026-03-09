defmodule KameramaniPhx.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  require Logger
  import Ecto.Query, warn: false
  alias KameramaniPhx.Repo

  alias KameramaniPhx.Subscriptions.Subscription
  @default_fx_provider_url "https://open.er-api.com/v6/latest/USD"
  @default_fx_timeout_ms 4_000

  @tier_prices %{
    1 => Decimal.new("1.99"),
    3 => Decimal.new("5.37"),
    6 => Decimal.new("10.15")
  }

  @doc """
  Returns the list of subscriptions.

  ## Examples

      iex> list_subscriptions()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.all(Subscription)
  end

  def subscriber_count(streamer_id) do
    from(s in Subscription, where: s.streamer_id == ^streamer_id)
    |> Repo.aggregate(:count)
  end

  def subscribed_to_streamer?(subscriber_id, streamer_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(s in Subscription,
      where:
        s.subscriber_id == ^subscriber_id and s.streamer_id == ^streamer_id and
          s.status == "active" and s.expires_at > ^now
    )
    |> Repo.exists?()
  end

  def tier_options do
    {:ok, fx_rate} = usd_kes_rate()

    Enum.map([1, 3, 6], fn tier ->
      {:ok, amount_usd} = tier_amount(tier)

      %{
        tier: tier,
        amount_usd: amount_usd,
        amount_kes: usd_to_kes(amount_usd, fx_rate),
        fx_rate: fx_rate
      }
    end)
  end

  @doc """
  Gets a single subscription.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(123)
      %Subscription{}

      iex> get_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription!(id), do: Repo.get!(Subscription, id)

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  def subscribe_to_streamer(subscriber_id, streamer_id, tier) when is_integer(tier) do
    with {:ok, amount_usd} <- tier_amount(tier),
         {:ok, fx_rate} <- usd_kes_rate() do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        subscriber_id: subscriber_id,
        streamer_id: streamer_id,
        tier: tier,
        amount_usd: amount_usd,
        amount_kes: usd_to_kes(amount_usd, fx_rate),
        fx_rate: fx_rate,
        currency: "KES",
        fx_fetched_at: now,
        status: "active",
        expires_at: expires_at_for_tier(tier)
      }

      case Repo.get_by(Subscription, subscriber_id: subscriber_id, streamer_id: streamer_id) do
        nil ->
          create_subscription(attrs)

        existing_sub ->
          existing_sub
          |> Subscription.changeset(attrs)
          |> Repo.update()
      end
    end
  end

  # Backward-compatible typo alias for existing calls.
  def subcribe_to_streamer(subscriber_id, streamer_id, tier, _amount) do
    subscribe_to_streamer(subscriber_id, streamer_id, tier)
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subscription.

  ## Examples

      iex> delete_subscription(subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  def change_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.changeset(subscription, attrs)
  end

  #if already subbed  or expired
  def is_subscribed?(nil, _streamer_id), do: false

  def is_subscribed?(%Subscription{expires_at: expires_at, status: status}, _streamer_id) do
    if status == "active" and DateTime.compare(expires_at, DateTime.utc_now()) == :gt do
      true
    else
      false
    end
  end

  defp tier_amount(tier) do
    case Map.fetch(@tier_prices, tier) do
      {:ok, amount} -> {:ok, amount}
      :error -> {:error, :invalid_tier}
    end
  end

  defp expires_at_for_tier(tier) do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.add(tier * 30 * 24 * 60 * 60, :second)
  end

  defp usd_to_kes(amount_usd, fx_rate) do
    amount_usd
    |> Decimal.mult(fx_rate)
    |> Decimal.round(2)
  end

  defp usd_kes_rate do
    fx_config = Application.get_env(:kameramani_phx, :fx, [])
    provider_url = Keyword.get(fx_config, :provider_url, @default_fx_provider_url)
    timeout = Keyword.get(fx_config, :timeout_ms, @default_fx_timeout_ms)

    with {:ok, _fallback_rate} <- fallback_rate(fx_config),
         {:ok, fetched_rate} <- fetch_rate(provider_url, timeout),
         :gt <- Decimal.compare(fetched_rate, Decimal.new(0)) do
      {:ok, fetched_rate}
    else
      _ ->
        {:ok, fallback_rate} = fallback_rate(fx_config)
        Logger.warning("Using fallback USD/KES FX rate for subscriptions")
        {:ok, fallback_rate}
    end
  end

  defp fetch_rate(provider_url, timeout) do
    case Req.get(url: provider_url, receive_timeout: timeout) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        body
        |> extract_kes_rate()
        |> decimal_from_value()

      _ ->
        {:error, :fx_fetch_failed}
    end
  end

  defp fallback_rate(fx_config) do
    fx_config
    |> Keyword.get(:usd_kes_fallback_rate, "130.0")
    |> decimal_from_value()
  end

  defp extract_kes_rate(body) when is_map(body) do
    get_in(body, ["rates", "KES"]) ||
      get_in(body, [:rates, :KES]) ||
      get_in(body, ["conversion_rates", "KES"]) ||
      get_in(body, [:conversion_rates, :KES]) ||
      get_in(body, ["data", "KES"]) ||
      get_in(body, [:data, :KES])
  end

  defp extract_kes_rate(_), do: nil

  defp decimal_from_value(%Decimal{} = value), do: {:ok, value}

  defp decimal_from_value(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> {:ok, decimal}
      _ -> {:error, :invalid_decimal}
    end
  end

  defp decimal_from_value(value) when is_integer(value), do: {:ok, Decimal.new(value)}

  defp decimal_from_value(value) when is_float(value) do
    value
    |> :erlang.float_to_binary(decimals: 6)
    |> decimal_from_value()
  end

  defp decimal_from_value(_), do: {:error, :invalid_decimal}
end
