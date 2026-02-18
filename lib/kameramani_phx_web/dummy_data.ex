defmodule KameramaniPhxWeb.DummyData do
  @moduledoc """
  This module provides hardcoded dummy data for streams,
  to be used by LiveViews like LandingLive and ChatLive
  when real database data is not yet available or desired.
  """

  @doc """
  Returns a hardcoded list of dummy stream data.
  """
  def get_stream_data do
    [
      %{
        # Using integer ID
        id: 1,
        stream_name: "Elden Ring Stream",
        streamer: "iShowSpeed",
        category: "Action",
        tags: ["RPG", "Adventure"],
        viewer_count: 20_000,
        avatar: "https://i.pravatar.cc/150?img=1"
      },
      %{
        id: 2,
        stream_name: "God of War Marathon",
        streamer: "FaZe Adapt",
        category: "Rage",
        tags: "Action",
        viewer_count: 12_000,
        avatar: "https://i.pravatar.cc/150?img=2"
      },
      %{
        id: 3,
        stream_name: "Shadow of Mordor Grind",
        streamer: "XQC",
        category: "Just Chatting",
        tags: "MMORPG",
        viewer_count: 34_000,
        avatar: "https://i.pravatar.cc/150?img=3"
      },
      %{
        id: 4,
        stream_name: "Ninja Storm: 4 Pro Play",
        streamer: "DBangz",
        category: "Weabo",
        tags: "Turn-Based",
        viewer_count: 11_400,
        avatar: "https://i.pravatar.cc/150?img=4"
      },
      %{
        id: 5,
        stream_name: "Chess: Multiverse of Madness Ranked",
        streamer: "Berleezy",
        category: "Role-Playing",
        tags: "Strategy",
        viewer_count: 19_800,
        avatar: "https://i.pravatar.cc/150?img=5"
      },
      %{
        id: 6,
        stream_name: "Forza 5 Speedrun",
        streamer: "Corpse Husband",
        category: "Talking",
        tags: "Racing",
        viewer_count: 27_000,
        avatar: "https://i.pravatar.cc/150?img=6"
      },
      %{
        id: 7,
        stream_name: "GTA VI Leaks & Gameplay",
        streamer: "Pokimane",
        category: "G-Bait",
        tags: "Action",
        viewer_count: 1738,
        avatar: "https://i.pravatar.cc/150?img=7"
      },
      %{
        id: 8,
        stream_name: "Cyberpunk: 2077 Full Playthrough",
        streamer: "M0istCr1tikal",
        category: "Speedrunning",
        tags: "RPG",
        viewer_count: 6767,
        avatar: "https://i.pravatar.cc/150?img=8"
      }
    ]
  end
end
