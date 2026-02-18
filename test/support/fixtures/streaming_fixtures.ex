defmodule KameramaniPhx.StreamingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KameramaniPhx.Streaming` context.
  """

  @doc """
  Generate a unique stream stream_key.
  """
  def unique_stream_stream_key, do: "some stream_key#{System.unique_integer([:positive])}"

  @doc """
  Generate a stream.
  """
  def stream_fixture(attrs \\ %{}) do
    {:ok, stream} =
      attrs
      |> Enum.into(%{
        is_live: true,
        stream_key: unique_stream_stream_key(),
        tags: ["option1", "option2"],
        title: "some title"
      })
      |> KameramaniPhx.Streaming.create_stream()

    stream
  end
end
