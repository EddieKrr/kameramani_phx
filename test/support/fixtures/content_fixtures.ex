defmodule KameramaniPhx.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Content` context.
  """

  @doc """
  Generate a unique category slug.
  """
  def unique_category_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "some name",
        slug: unique_category_slug()
      })
      |> KameramaniPhx.Content.create_category()

    category
  end
end
