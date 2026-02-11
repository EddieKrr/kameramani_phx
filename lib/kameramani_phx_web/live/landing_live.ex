defmodule KameramaniPhxWeb.LandingLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents
  import KameramaniPhxWeb.CardComponents

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_scope}

  def mount(_params, _session, socket) do
    stream = [
      %{
        stream_id: 1,
        game: "Elden Ring",
        streamer: "iShowSpeed",
        category: "Action",
        genre: "RPG",
        viewer_count: 20_000,
        avatar: ""
      },
      %{
        stream_id: 2,
        game: "God of War",
        streamer: "FaZe Adapt",
        category: "Rage",
        genre: "Action",
        viewer_count: 12_000,
        avatar: ""
      },
      %{
        stream_id: 3,
        game: "Shadow of Mordor",
        streamer: "XQC",
        category: "Just Chatting",
        genre: "MMORPG",
        viewer_count: 34_000,
        avatar: ""
      },
      %{
        stream_id: 4,
        game: "Ninja Storm: 4",
        streamer: "DBangz",
        category: "Weabo",
        genre: "Turn-Based",
        viewer_count: 11_400,
        avatar: ""
      },
      %{
        stream_id: 5,
        game: "Chess: Multiverse of Madness",
        streamer: "Berleezy",
        category: "Role-Playing",
        genre: "Strategy",
        viewer_count: 19_800,
        avatar: ""
      },
      %{
        stream_id: 6,
        game: "Forza 5",
        streamer: "Corpse Husband",
        category: "Talking",
        genre: "Racing",
        viewer_count: 27_000,
        avatar: ""
      },
      %{
        stream_id: 7,
        game: "GTA VI",
        streamer: "Pokimane",
        category: "G-Bait",
        genre: "Action",
        viewer_count: 1738,
        avatar: ""
      },
      %{
        stream_id: 8,
        game: "Cyberpunk: 2077",
        streamer: "M0istCr1tikal",
        category: "Speedrunning",
        genre: "RPG",
        viewer_count: 6767,
        avatar: ""
      }
    ]

    {:ok, assign(socket, stream: stream)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Landing Page")}
  end
end
