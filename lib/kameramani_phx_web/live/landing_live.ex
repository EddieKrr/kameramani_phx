defmodule KameramaniPhxWeb.LandingLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents
  import KameramaniPhxWeb.CardComponents
  alias KameramaniPhxWeb.DummyData

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    stream_data = DummyData.get_stream_data()

    {:ok, assign(socket, streams_data: stream_data)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Landing Page")}
  end
end
