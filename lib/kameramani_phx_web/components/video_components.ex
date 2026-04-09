defmodule KameramaniPhxWeb.VideoComponents do
  use Phoenix.Component
  import KameramaniPhxWeb.CoreComponents

  attr :id, :string, required: true
  attr :url, :string, required: true
  attr :stream_id, :string, required: true
  attr :is_live, :boolean, default: false
  attr :poster, :string, default: nil
  attr :class, :string, default: nil

  def video_player(assigns) do
    ~H"""
    <div
      id={"player-container-#{@id}"}
      class={[
        "relative aspect-video bg-black rounded-3xl overflow-hidden group shadow-2xl border border-white/5",
        @class
      ]}
    >
      <%= if @is_live do %>
        <div id={"#{@id}-video-wrapper"} phx-update="ignore" class="absolute inset-0 w-full h-full">
          <video
            id={@id}
            phx-hook="VideoPlayer"
            data-hls-url={@url}
            class="w-full h-full object-contain cursor-pointer"
            playsinline
            autoplay
            muted
          >
          </video>
        </div>

        <div
          id={"#{@id}-center-control"}
          class="absolute inset-0 flex items-center justify-center pointer-events-none"
        >
          <div class="p-6 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 opacity-0 transition-all duration-300 scale-75 group-hover:scale-100 group-[.is-paused]:opacity-100">
            <.svg variant="play" class="w-12 h-12 text-white" />
          </div>
        </div>

        <div class="absolute bottom-0 left-0 right-0 p-4 translate-y-2 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-300 z-20">
          <div class="flex items-center gap-4 px-4 py-3 rounded-2xl bg-slate-900/40 backdrop-blur-md border border-white/10 shadow-2xl">
            <button
              id={"#{@id}-play-pause"}
              class="text-white hover:text-blue-400 transition-colors"
              title="Toggle Play/Pause"
            >
              <.svg variant="play" class="w-6 h-6 player-play-icon" />
              <.svg variant="pause" class="w-6 h-6 player-pause-icon hidden" />
            </button>

            <div class="flex items-center gap-2 group/volume w-32">
              <button id={"#{@id}-mute"} class="text-white hover:text-blue-400 transition-colors">
                <.svg variant="speaker-wave" class="w-5 h-5 player-unmuted-icon" />
                <.svg variant="speaker-x-mark" class="w-5 h-5 player-muted-icon hidden" />
              </button>
              <input
                id={"#{@id}-volume-slider"}
                type="range"
                min="0"
                max="100"
                value="100"
                class="range range-xs range-primary bg-white/10"
              />
            </div>

            <div class="flex-1"></div>

            <button class="text-white/60 hover:text-white transition-colors">
              <.svg variant="gear" class="w-5 h-5" />
            </button>

            <button
              id={"#{@id}-fullscreen"}
              class="text-white hover:text-blue-400 transition-colors"
              title="Toggle Fullscreen"
            >
              <.svg variant="fullscreen" class="w-5 h-5" />
            </button>
          </div>
        </div>

        <div
          id={"#{@id}-loader"}
          class="absolute inset-0 flex items-center justify-center bg-black/40 backdrop-blur-sm hidden z-30"
        >
          <span class="loading loading-spinner loading-lg text-blue-400"></span>
        </div>
      <% else %>
        <div class="absolute inset-0 flex items-center justify-center bg-slate-900/80 backdrop-blur-xl">
          <div class="text-center space-y-4">
            <div class="relative inline-block">
              <div class="w-20 h-20 bg-blue-500/20 blur-2xl rounded-full absolute -inset-2 animate-pulse">
              </div>
              <.icon name="hero-video-camera-slash" class="w-12 h-12 text-slate-500 relative z-10" />
            </div>
            <p class="text-slate-400 font-medium tracking-tight uppercase text-xs">
              Streamer is Offline
            </p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
