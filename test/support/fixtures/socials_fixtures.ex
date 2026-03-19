defmodule KameramaniPhx.SocialsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Socials` context.
  """

  @doc """
  Generate a social_account.
  """
  def social_account_fixture(attrs \\ %{}) do
    user =
      case attrs[:user] || attrs["user"] do
        nil -> KameramaniPhx.AccountsFixtures.user_fixture()
        user -> user
      end

    attrs = attrs |> Map.delete(:user) |> Map.delete("user")

    {:ok, social_account} =
      KameramaniPhx.Socials.add_social_account(
        user,
        Enum.into(attrs, %{
          platform: "youtube",
          url: "some url",
          username: "some username"
        })
      )

    social_account
  end
end
