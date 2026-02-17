defmodule KameramaniPhxWeb.Streaming.Settings.StreamSettings do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.CoreComponents

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Stream Settings")}
  end
end
