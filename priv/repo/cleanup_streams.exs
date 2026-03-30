alias KameramaniPhx.Repo
alias KameramaniPhx.Streaming
alias KameramaniPhx.Streaming.Stream

IO.puts("🧹 Cleaning up all live streams...")

Repo.all(Stream)
|> Enum.each(fn stream ->
  Streaming.update_stream(stream, %{is_live: false})
end)

IO.puts("✅ All streams are now offline.")
