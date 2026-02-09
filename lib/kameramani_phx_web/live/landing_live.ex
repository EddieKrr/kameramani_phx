defmodule KameramaniPhxWeb.LandingLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents
  import KameramaniPhxWeb.CardComponents

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_scope}

  def mount(_params, _session, socket) do
    stream = [
      %{stream_id: 1, game: "Elden Ring", streamer: "iShowSpeed", category: "Action", genre: "RPG", viewer_count: 20_000 , avatar: ""},
      %{stream_id: 2, game: "God of War", streamer: "FaZe Adapt", category: "Rage", genre: "Action", viewer_count: 12_000, avatar: ""},
      %{stream_id: 3, game: "Shadow of Mordor", streamer: "XQC", category: "Just Chatting", genre: "MMORPG", viewer_count: 34_000, avatar: ""},
      %{stream_id: 4, game: "Ninja Storm: 4", streamer: "DBangz", category: "Weabo", genre: "Turn-Based", viewer_count: 11_400, avatar: ""},
      %{stream_id: 5, game: "Chess: Multiverse of Madness", streamer: "Berleezy", category: "Role-Playing", genre: "Strategy", viewer_count: 19_800, avatar: ""},
      %{stream_id: 6, game: "Forza 5", streamer: "Corpse Husband", category: "Talking", genre: "Racing", viewer_count: 27_000, avatar: ""},
      %{stream_id: 7, game: "GTA VI", streamer: "Pokimane", category: "G-Bait", genre: "Action", viewer_count: 1738, avatar: ""},
      %{stream_id: 8, game: "Cyberpunk: 2077", streamer: "M0istCr1tikal", category: "Speedrunning", genre: "RPG", viewer_count: 6767, avatar: ""}
    ]

    {:ok, assign(socket, stream: stream)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen w-full overflow-hidden">
      <div class="w-64 bg-slate-800 border-r-2 border-r-slate-700 flex-shrink-0"></div>
      <div class="flex-1 bg-slate-900 overflow-y-auto">
        <div class="relative w-full aspect-video max-h-[500px] bg-black shadow-xl mb-6">
          <div class="absolute bottom-0 w-full h-1/3 bg-gradient-to-b from-transparent to-black pointer-events-none">
            <div class="flex absolute bottom-4 left-4">
              <.sidebar_item name={"Jleel"} game={"Sims 4"} viewer_count={5000} src="https://ui-avatars.com/api/?background=random"/>
            </div>
          </div>
          <div class="lv-ind absolute top-4 left-4 z-10 bg-red-950 h-4 w-4 rounded-full"></div>
        </div>
        <div class="px-6 pb-6">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-6">
            <.card :for={card <- @stream} id={card.stream_id} game={card.game} streamer={card.streamer } category={card.category} genre={card.genre} viewer_count={card.viewer_count} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
