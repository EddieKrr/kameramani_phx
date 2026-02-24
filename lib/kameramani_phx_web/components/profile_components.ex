defmodule KameramaniPhxWeb.ProfileComponents do
  use Phoenix.Component
  import KameramaniPhxWeb.CoreComponents

  attr :username, :string, required: true
  attr :name, :string, required: true
  attr :avatar_url, :string, required: true
  attr :is_live, :boolean, default: false

  def profile_header(assigns) do
    ~H"""
    <div class="bg-[#18181b] border border-white/5 rounded-2xl p-8 mb-8 shadow-2xl">
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
          <div class="flex items-center gap-3 mb-2">
            <h1 class="text-4xl font-bold">{@name}</h1>
            <!-- Offline Status Badge -->
            <div class="bg-gray-600 text-white px-3 py-1 rounded-full text-sm font-medium">
              OFFLINE
            </div>
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
          <button class="bg-indigo-600 hover:bg-indigo-500 text-white px-6 py-3 rounded-lg font-semibold transition-colors flex items-center gap-2">
            <.svg variant="envelope" class="h-5 w-5" /> Send Message
          </button>
          <button class="bg-purple-600 hover:bg-purple-500 text-white px-6 py-3 rounded-lg font-semibold transition-colors flex items-center gap-2">
            <.svg variant="heart" class="h-5 w-5" /> Follow
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :bio, :string, default: nil
  attr :age, :string, default: "Not Specified"
  attr :member_since, :string, default: "Unknown"
  attr :email, :string, required: true

  def about_section(assigns) do
    ~H"""
    <div class="bg-[#18181b] border border-white/5 rounded-2xl shadow-2xl mb-8">
      <div class="flex flex-wrap border-b border-white/5">
        <button
          phx-click="set_active_tab"
          phx-value-tab="about"
          class="border-white bg-white/10"
        >
          About
        </button>
      </div>

    <!-- Tab Content -->
      <div class="p-8">
            <%!-- <h3 class="text-2xl font-bold text-white mb-6">About {@user.name}</h3> --%>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">

              <div class="bg-white/5 rounded-lg p-6">
                <h4 class="font-semibold font-title text-lg text-indigo-300 mb-2 uppercase tracking-wider">
                  Username
                </h4>
                <%!-- <p class="text-white font-medium">{@user.username}</p> --%>
              </div>

              <div class="bg-white/5 rounded-lg p-6">
                <h4 class="text-lg font-title font-semibold text-indigo-300 mb-2 uppercase tracking-wider">
                  Member For
                </h4>
                <p class="text-white font-medium">{@member_since}</p>
              </div>

              <div class="bg-white/5 rounded-xl p-6 text-indigo-300 mb-2">
                <h4 class = "font-title text-lg"></h4>
                <p class = "font-title text-lg"></p>
              </div>
            </div>
      </div>
    </div>
    """
  end
end
