defmodule KameramaniPhxWeb.LandingLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents
  import KameramaniPhxWeb.CardComponents

  def mount(_params, _session, socket) do
    stream = [
      %{id: 1, game: "Elden Ring", streamer: "iShowSpeed", category: "Action", genre: "RPG", viewer_count: 20_000 , avatar: ""},
      %{id: 2, game: "God of War", streamer: "FaZe Adapt", category: "Rage", genre: "Action", viewer_count: 12_000, avatar: ""},
      %{id: 3, game: "Shadow of Mordor", streamer: "XQC", category: "Just Chatting", genre: "MMORPG", viewer_count: 34_000, avatar: ""},
      %{id: 4, game: "Ninja Storm: 4", streamer: "DBangz", category: "Weabo", genre: "Turn-Based", viewer_count: 11_400, avatar: ""},
      %{id: 5, game: "Chess: Multiverse of Madness", streamer: "Berleezy", category: "Role-Playing", genre: "Strategy", viewer_count: 19_800, avatar: ""},
      %{id: 6, game: "Forza 5", streamer: "Corpse Husband", category: "Talking", genre: "Racing", viewer_count: 27_000, avatar: ""},
      %{id: 7, game: "GTA VI", streamer: "Pokimane", category: "G-Bait", genre: "Action", viewer_count: 1738, avatar: ""},
      %{id: 8, game: "Cyberpunk: 2077", streamer: "M0istCr1tikal", category: "Speedrunning", genre: "RPG", viewer_count: 6767, avatar: ""}
  ]

    {:ok, assign(socket, stream: stream)}
  end

  def render(assigns) do
    ~H"""
    <div class = "grid grid-cols-[256px_1fr] h-screen w-full overflow-hidden">
      <div class="bg-slate-800 border-r-2 border-r-slate-700"></div>
      <div class="bg-slate-900 overflow-y-auto">
        <div class="nvbr flex items-center justify-between px-6 sticky top-0 z-50 w-3/4 h-12 rounded-full bg-gray-700/90 mx-auto"></div>
        <div class="lv-cntnr relative w-full aspect-video max-h-[600px] bg-black shadow-2xl">
          <div class="scrim absolute bottom-0 w-full h-1/3 bg-gradient-to-b from-transparent to-black pointer-events-none">
            <div class="lv-btn flex absolute bottom-4 left-4">
              <.sidebar_item name ={"Jleel"} game={"Sims 4"} viewer_count={5000} src="https://ui-avatars.com/api/?background=random"/>
            </div>
          </div>
          <div class="lv-ind absolute top-4 left-4 z-10 bg-red-950 h-4 w-4 rounded-full"></div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-4 m-2">
          <.card :for={card <- @stream} game={card.game} streamer={card.streamer } category={card.category} genre={card.genre} viewer_count={card.viewer_count} avatar={card.avatar}></.card>
        </div>
      </div>
    </div>
    """
  end
end
