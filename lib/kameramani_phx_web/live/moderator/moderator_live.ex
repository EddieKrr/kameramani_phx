defmodule KameramaniPhxWeb.ModeratorLive do
  use KameramaniPhxWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold">Moderator Dashboard</h1>
      <p>Welcome to the moderator panel.</p>
    </div>
    """
  end
end
