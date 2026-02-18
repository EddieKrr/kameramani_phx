defmodule KameramaniPhxWeb.Streaming.Settings.StreamSettingsLive do
  use KameramaniPhxWeb, :live_view


  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Stream Settings")}
  end
end
