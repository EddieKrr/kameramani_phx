defmodule KameramaniPhx.SocialsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Socials` context.
  """

  @doc """
  Generate a social_account.
  """
  def social_account_fixture(attrs \\ %{}) do
    {:ok, social_account} =
      attrs
      |> Enum.into(%{
        platform: "some platform",
        url: "some url",
        username: "some username"
      })
      |> KameramaniPhx.Socials.create_social_account()

    social_account
  end
end
