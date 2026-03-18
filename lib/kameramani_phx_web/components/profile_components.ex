defmodule KameramaniPhxWeb.ProfileComponents do
  use Phoenix.Component
  import KameramaniPhxWeb.CoreComponents
  import KameramaniPhxWeb.CardComponents

  attr :username, :string, required: true
  attr :name, :string, required: true
  attr :avatar_url, :string, required: true
  attr :is_live, :boolean, default: false
  attr :is_verified, :boolean, default: false
  attr :can_follow, :boolean, default: false

  def profile_header(assigns) do
    ~H"""
    <div class="glass-pane">
      <div class="flex flex-col md:flex-row items-center md:items-start gap-8">
        <!-- Profile Picture -->
        <div class="shrink-0">
          <div class="relative">
            <img
              src={@avatar_url}
              alt="{@name}'s Profile Picture"
              class="w-32 h-32 rounded-full object-cover border-4 border-indigo-500/20 shadow-xl"
            />
            <!-- Online Status Indicator -->
            <div class="absolute bottom-2 right-2 w-6 h-6 bg-gray-500 rounded-full border-4 border-[#18181b] flex items-center justify-center">
              <div class="w-2 h-2 bg-white rounded-full"></div>
            </div>
          </div>
        </div>

        <div class="flex-1 text-center md:text-left">
          <div class="flex items-center gap-3 mb-2 justify-center md:justify-start">
            <h1 class="text-4xl font-bold">{@name}</h1>
            <%= if @is_verified do %>
              <div class="tooltip tooltip-right" data-tip="Verified Creator">
                <.svg
                  variant="check-badge"
                  class="h-6 w-6 text-blue-400 drop-shadow-[0_0_8px_rgba(96,165,250,0.5)]"
                />
              </div>
            <% end %>
            <%= if @is_live do %>
              <.icon name="hero-signal" class="h-5 w-5 text-red-500 animate-pulse" />
              <span class="text-red-500 rounded-full bg-white/10 px-3 py-1 text-sm font-medium">
                Live
              </span>
            <% else %>
              <span class="bg-gray-600 text-white px-3 py-1 rounded-full text-sm font-medium">
                Offline
              </span>
            <% end %>
          </div>

          <p class="text-xl text-gray-300 mb-4">@{@username}</p>

          <%!-- <%= if @bio && @bio != "" do %>
            <div class="bg-white/5 rounded-lg p-4 mb-4">
              <p class="text-gray-300 leading-relaxed">{@bio}</p>
            </div>
          <% else %>
            <div class="bg-white/5 rounded-lg p-4 mb-4">
              <p class="text-gray-500 italic">No bio yet...</p>
            </div>
          <% end %> --%>

          <div class="flex flex-wrap gap-6 justify-center md:justify-start">
            <%!-- <div class="text-center">
              <p class="text-2xl font-bold text-white">{@age || "N/A"}</p>
              <p class="text-sm text-gray-400">Age</p>
            </div> --%>
            <div class="text-center">
              <p class="text-2xl font-bold text-white">
                <%!-- {@time} --%>
              </p>
              <p class="text-sm text-gray-400">Member</p>
            </div>
          </div>
        </div>
        <!-- Action Buttons -->
        <div class="flex justify-center gap-4">
          <%!-- <%= if @current_user.user && @current_user.user.id != @streamer_id do %>
            <button
              phx-click="toggle_follow"
              class={"px-4 py-1.5 rounded font-bold text-sm transition-colors flex items-center gap-2 shadow " <>
                if(@is_following, do: "bg-gray-700 hover:bg-gray-600 text-white", else: "bg-indigo-400 hover:bg-indigo-500 text-black")}
            >
              <%= if @is_following do %>
                <.svg variant="heart-solid" class="w-4 h-4 text-red-500" /> Unfollow
              <% else %>
                <.svg variant="heart" class="w-4 h-4" /> Follow
              <% end %>
            </button>
          <% else %>
            <%= if !@current_user.user do %>
              <button
                phx-click="toggle_follow"
                class="bg-[#bf94ff] hover:bg-[#a970ff] text-black px-4 py-1.5 rounded font-bold text-sm transition-colors flex items-center gap-2 shadow"
              >
                <.svg variant="heart" class="w-4 h-4" /> Follow
              </button>
            <% end %> --%>
        </div>
      </div>
    </div>
    """
  end

  attr :bio, :string, default: nil
  attr :age, :string, default: "Not Specified"
  attr :member_since, :string, default: "Unknown"
  attr :email, :string, required: true
  attr :username, :string, required: true
  attr :social_accounts, :list, default: []

  def about_section(assigns) do
    ~H"""
    <div class="glass-pane border border-white/5 rounded-2xl shadow-2xl mb-8">
      <div class="p-8">
        <h3 class="text-2xl font-bold text-white mb-6 capitalize">About {@username}</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="bg-white/5 rounded-lg p-6">
            <h4 class="font-semibold font-title text-lg text-indigo-200 mb-2 uppercase tracking-wider">
              Username
            </h4>
            <p class="text-white font-medium">{@username}</p>
          </div>

          <div class="bg-white/5 rounded-lg p-6">
            <h4 class="text-lg font-title font-semibold text-indigo-200 mb-2 uppercase tracking-wider">
              Member For
            </h4>
            <p class="text-white font-medium">{@member_since}</p>
          </div>

          <div class="bg-white/5 rounded-xl p-6 text-indigo-200 mb-2">
            <h4 class="font-title text-lg mb-2 uppercase tracking-wider">Biography</h4>
            <p class="font-medium">{@bio}</p>
          </div>

          <div class="bg-white/5 rounded-xl p-6 text-indigo-200 mb-2">
            <h4 class="font-title text-lg mb-4 uppercase tracking-wider">Socials</h4>
            <div class="flex flex-wrap gap-4">
              <%= if Enum.empty?(@social_accounts) do %>
                <p class="text-slate-500 italic text-sm">No social accounts linked</p>
              <% else %>
                <a
                  :for={social <- @social_accounts}
                  href={social.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="group relative flex items-center justify-center w-12 h-12 rounded-xl bg-black/40 border border-white/5 hover:border-blue-500/50 hover:bg-blue-500/10 transition-all duration-300"
                >
                  <.svg
                    variant={social.platform}
                    class="w-6 h-6 text-slate-400 group-hover:text-blue-400 group-hover:scale-110 transition-all"
                  />
                  <span class="absolute -top-10 scale-0 group-hover:scale-100 bg-slate-800 text-white text-[10px] px-2 py-1 rounded font-bold uppercase tracking-widest whitespace-nowrap transition-all shadow-xl">
                    {social.username}
                  </span>
                </a>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :patch, :string, required: true
  attr :label, :string, required: true
  attr :is_active, :boolean, default: false

  def profile_tab(assigns) do
    ~H"""
    <.link
      patch={@patch}
      class={[
        "px-4 py-2 rounded-lg",
        if(@is_active, do: "bg-indigo-900 text-white", else: "text-gray-400 hover:text-gray-800")
      ]}
    >
      {@label}
    </.link>
    """
  end

  attr :vods, :list, required: true

  def video_section(assigns) do
    ~H"""
    <div :for={vod <- @vods} class="flex flex-row">
      <.card
        stream_name={vod.title}
        streamer={vod.user.username}
        category={vod.category}
        avatar={vod.user.profile_picture}
        viewer_count={vod.vod_play_count}
        id={vod.id}
        is_live={false}
        thumbnail_url={"/thumbnails/#{vod.id}.jpg"}
      />
    </div>
    """
  end

  def home_section(assigns) do
    ~H"""
    """
  end
end
