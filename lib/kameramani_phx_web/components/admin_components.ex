defmodule KameramaniPhxWeb.AdminComponents do
  use Phoenix.Component
  import KameramaniPhxWeb.CoreComponents

  attr :item, :map, required: true
  attr :active, :boolean, default: false
  attr :prev_active, :boolean, default: false
  attr :next_active, :boolean, default: false

  def sidebar_link(assigns) do
    ~H"""
    <%!-- <div class={[
      "relative transition-colors duration-300",
      if(@active, do: "bg-white pl-4", else: "bg-blue-200")
    ]}>

      <div class={[
        "transition-all duration-300 ease-in-out block",
        @active && "bg-blue-200 rounded-l-full text-blue-900 font-bold py-3 px-6 -mr-[1px] relative z-10",
        @prev_active && "bg-white rounded-tr-3xl text-black py-3 px-6",
        @next_active && "bg-white rounded-br-3xl text-black py-3 px-6",
        !@active && !@prev_active && !@next_active && "bg-white text-black hover:bg-gray-50 py-3 px-6"
      ]}>
        <.link patch={@item.path} class="block w-full h-full">
          {@item.label}
        </.link>
      </div>

    </div> --%>
    <div class={["relative", if(@active, do: "bg-white pl-4", else: "bg-blue-200")]}>
      <%= cond do %>
        <% @active -> %>
          <.link
            patch={@item.path}
            class="block bg-blue-200 pl-6 py-3 rounded-l-full text-blue-900 font-bold relative z-10"
          >
            {@item.label}
          </.link>
        <% @prev_active -> %>
          <div class="bg-white px-6 py-3 rounded-tr-3xl text-black">
            <.link navigate={@item.path}>{@item.label}</.link>
          </div>
        <% @next_active -> %>
          <div class="bg-white px-6 py-3 rounded-br-3xl text-black">
            <.link navigate={@item.path}>{@item.label}</.link>
          </div>
        <% true -> %>
          <div class="bg-white px-6 py-3 text-black hover:bg-gray-50 transition-colors">
            <.link navigate={@item.path}>{@item.label}</.link>
          </div>
      <% end %>
    </div>


  """
end

  attr :users, :list, required: true
  def user_tab(assigns) do
  ~H"""
  <div class="bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full col-span-5 overflow-y-auto h-screen">

    <div class="flex justify-between items-center mb-8">
      <div>
        <h2 class="text-3xl font-bold text-slate-800 tracking-tight">User Management</h2>
        <p class="text-slate-500 mt-1">View and manage Kameramani accounts.</p>
      </div>
      <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-lg">
        + Add User
      </button>
    </div>

    <div class="flex gap-4 mb-6">
      <div class="relative flex-1 max-w-md">
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
          <.svg variant="search" class="w-5 h-5" />
        </div>
        <input
          type="text"
          placeholder="Search by username or email..."
          class="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700"
        />
      </div>
    </div>

    <div class="overflow-x-auto rounded-xl border border-gray-200">
      <table class="w-full text-left border-collapse">

        <thead class="bg-gray-50 text-slate-500 text-sm font-semibold uppercase tracking-wider">
          <tr>
            <th class="py-4 px-6 border-b border-gray-200">User</th>
            <th class="py-4 px-6 border-b border-gray-200">Role</th>
            <th class="py-4 px-6 border-b border-gray-200">Status</th>
            <th class="py-4 px-6 border-b border-gray-200">Community</th>
            <th class="py-4 px-6 border-b border-gray-200">Joined</th>
            <th class="py-4 px-6 border-b border-gray-200 text-right">Actions</th>
          </tr>
        </thead>

        <tbody class="divide-y divide-gray-200 text-slate-700">
          <%= for users <- @users do %>
          <tr class="hover:bg-blue-50/50 transition-colors group">

            <td class="py-4 px-6 flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold shadow-sm">
                {String.first(users.username)|> String.upcase()}
              </div>
              <div>
                <div class="font-bold text-slate-900 group-hover:text-blue-600 transition-colors">
                  {users.email}
                </div>

              </div>
            </td>

            <td class="py-4 px-6">
              <span :for={role <- users.roles} class="bg-purple-100 text-purple-700 py-1 px-3 rounded-full text-xs font-bold border border-purple-200">
                {role.name}
              </span>
            </td>

            <td class="py-4 px-6">
                    <%= if Map.get(users, :is_live) do %>
                      <span class="rounded-full bg-green-400 border-2 border-green-200 uppercase animate-pulse">live</span>
                    <%else%>
                      <span class="rounded-full bg-red-500 border-2 border-red-200 uppercase">offline</span>
                    <%end %>
            </td>

            <td class="py-4 px-6">
              <div class="flex flex-wrap gap-2 text-xs font-semibold">
                <span class="rounded-full bg-amber-100 px-3 py-1 text-amber-700">
                  Subs {users.subscriber_count}
                </span>
                <span class="rounded-full bg-sky-100 px-3 py-1 text-sky-700">
                  Following {users.following_count}
                </span>
                <span class="rounded-full bg-emerald-100 px-3 py-1 text-emerald-700">
                  Followers {users.follower_count}
                </span>
              </div>
            </td>

            <td class="py-4 px-6 text-sm text-slate-500">{Calendar.strftime(users.inserted_at, "%B, %d, %Y")}</td>

            <td class="py-4 px-6 text-right">
              <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">Edit</button>
              <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">Ban</button>
            </td>
          </tr>

          <% end %>
        </tbody>
      </table>
    </div>

  </div>
  """
end
  def category_tab(assigns) do
  ~H"""
  <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">

    <div class="flex justify-between items-center mb-8">
      <div>
        <h2 class="text-3xl font-bold text-slate-800 tracking-tight">Stream Categories</h2>
        <p class="text-slate-500 mt-1">Manage and organize the content classifications for Kameramani.</p>
      </div>
      <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
        + New Category
      </button>
    </div>

    <div class="flex gap-4 mb-8 border-b border-gray-100 pb-6">
      <div class="relative flex-1 max-w-md">
        <input
          type="text"
          placeholder="Search categories..."
          class="w-full pl-4 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700"
        />
      </div>
      <button class="px-4 py-2 bg-gray-50 border border-gray-200 text-slate-600 rounded-xl hover:bg-gray-100 font-medium transition-colors">
        Filter
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

      <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-purple-300 transition-all group bg-white relative overflow-hidden">
        <div class="absolute top-0 left-0 w-1 h-full bg-purple-500"></div>

        <div class="flex justify-between items-start mb-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center font-bold text-xl">
              🎮
            </div>
            <h3 class="font-bold text-xl text-slate-800 group-hover:text-purple-700 transition-colors">
              Gaming
            </h3>
          </div>
          <button class="text-slate-400 hover:text-slate-600">•••</button>
        </div>

        <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
          Live gameplay, esports tournaments, and gaming talk shows.
        </p>

        <div class="flex items-center justify-between border-t border-gray-100 pt-4">
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">1,204</span> Active Streams
          </div>
          <div class="text-xs font-semibold text-purple-600 bg-purple-50 px-2 py-1 rounded-md">
            Popular
          </div>
        </div>
      </div>

      <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-blue-300 transition-all group bg-white relative overflow-hidden">
        <div class="absolute top-0 left-0 w-1 h-full bg-blue-500"></div>

        <div class="flex justify-between items-start mb-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xl">
              🎵
            </div>
            <h3 class="font-bold text-xl text-slate-800 group-hover:text-blue-700 transition-colors">
              Music & Audio
            </h3>
          </div>
          <button class="text-slate-400 hover:text-slate-600">•••</button>
        </div>

        <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
          Live DJ sets, acoustic performances, and music production.
        </p>

        <div class="flex items-center justify-between border-t border-gray-100 pt-4">
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">452</span> Active Streams
          </div>
        </div>
      </div>

      <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-emerald-300 transition-all group bg-white relative overflow-hidden">
        <div class="absolute top-0 left-0 w-1 h-full bg-emerald-500"></div>

        <div class="flex justify-between items-start mb-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center font-bold text-xl">
              💻
            </div>
            <h3 class="font-bold text-xl text-slate-800 group-hover:text-emerald-700 transition-colors">
              Tech & Coding
            </h3>
          </div>
          <button class="text-slate-400 hover:text-slate-600">•••</button>
        </div>

        <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
          Software development, hardware building, and tech reviews.
        </p>

        <div class="flex items-center justify-between border-t border-gray-100 pt-4">
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">128</span> Active Streams
          </div>
        </div>
      </div>

      <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-amber-300 transition-all group bg-white relative overflow-hidden">
        <div class="absolute top-0 left-0 w-1 h-full bg-amber-500"></div>

        <div class="flex justify-between items-start mb-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center font-bold text-xl">
              💬
            </div>
            <h3 class="font-bold text-xl text-slate-800 group-hover:text-amber-700 transition-colors">
              Just Chatting
            </h3>
          </div>
          <button class="text-slate-400 hover:text-slate-600">•••</button>
        </div>

        <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
          Casual conversations, Q&A sessions, and vlogging.
        </p>

        <div class="flex items-center justify-between border-t border-gray-100 pt-4">
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">3,891</span> Active Streams
          </div>
          <div class="text-xs font-semibold text-amber-600 bg-amber-50 px-2 py-1 rounded-md">
            Trending
          </div>
        </div>
      </div>

    </div>
  </div>
  """
end

  def tag_tab(assigns) do
  ~H"""
  <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">

    <div class="flex justify-between items-center mb-8">
      <div>
        <h2 class="text-3xl font-bold text-slate-800 tracking-tight">Tag Management</h2>
        <p class="text-slate-500 mt-1">Monitor and moderate granular stream descriptors.</p>
      </div>
      <div class="flex gap-3">
        <button class="bg-white border border-gray-200 text-slate-700 hover:bg-gray-50 font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
          Merge Tags
        </button>
        <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
          + Create Tag
        </button>
      </div>
    </div>

    <div class="flex gap-4 mb-6">
      <div class="relative flex-1 max-w-md">
        <input
          type="text"
          placeholder="Search by tag name..."
          class="w-full pl-4 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700"
        />
      </div>
      <select class="px-4 py-2 bg-gray-50 border border-gray-200 text-slate-600 rounded-xl hover:bg-gray-100 font-medium transition-colors outline-none focus:ring-2 focus:ring-blue-500">
        <option>Sort by: Popularity</option>
        <option>Sort by: Newest</option>
        <option>Sort by: Name (A-Z)</option>
      </select>
    </div>

    <div class="overflow-hidden rounded-xl border border-gray-200">
      <table class="w-full text-left border-collapse bg-white">

        <thead class="bg-gray-50 text-slate-500 text-xs font-bold uppercase tracking-wider">
          <tr>
            <th class="py-4 px-6 border-b border-gray-200 w-1/3">Tag Name</th>
            <th class="py-4 px-6 border-b border-gray-200">Type</th>
            <th class="py-4 px-6 border-b border-gray-200">Current Usage</th>
            <th class="py-4 px-6 border-b border-gray-200">7-Day Trend</th>
            <th class="py-4 px-6 border-b border-gray-200 text-right">Actions</th>
          </tr>
        </thead>

        <tbody class="divide-y divide-gray-100 text-slate-700">

          <tr class="hover:bg-slate-50 transition-colors group">
            <td class="py-4 px-6">
              <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                <span class="text-slate-400 group-hover:text-blue-400">#</span>Speedrun
              </div>
            </td>
            <td class="py-4 px-6">
              <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">System</span>
            </td>
            <td class="py-4 px-6 font-semibold text-slate-800">
              8,492 <span class="text-slate-400 font-normal text-sm">streams</span>
            </td>
            <td class="py-4 px-6">
              <div class="flex items-center gap-1 text-emerald-600 font-medium text-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
                +12%
              </div>
            </td>
            <td class="py-4 px-6 text-right">
              <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">Edit</button>
              <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">Delete</button>
            </td>
          </tr>

          <tr class="hover:bg-slate-50 transition-colors group">
            <td class="py-4 px-6">
              <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                <span class="text-slate-400 group-hover:text-blue-400">#</span>AMA
              </div>
            </td>
            <td class="py-4 px-6">
              <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">User Created</span>
            </td>
            <td class="py-4 px-6 font-semibold text-slate-800">
              3,104 <span class="text-slate-400 font-normal text-sm">streams</span>
            </td>
            <td class="py-4 px-6">
              <div class="flex items-center gap-1 text-emerald-600 font-medium text-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
                +5%
              </div>
            </td>
            <td class="py-4 px-6 text-right">
              <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">Edit</button>
              <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">Delete</button>
            </td>
          </tr>

          <tr class="hover:bg-slate-50 transition-colors group">
            <td class="py-4 px-6">
              <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                <span class="text-slate-400 group-hover:text-blue-400">#</span>Elixir
              </div>
            </td>
            <td class="py-4 px-6">
              <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">User Created</span>
            </td>
            <td class="py-4 px-6 font-semibold text-slate-800">
              412 <span class="text-slate-400 font-normal text-sm">streams</span>
            </td>
            <td class="py-4 px-6">
              <div class="flex items-center gap-1 text-slate-400 font-medium text-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4"></path></svg>
                0%
              </div>
            </td>
            <td class="py-4 px-6 text-right">
              <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">Edit</button>
              <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">Delete</button>
            </td>
          </tr>

          <tr class="hover:bg-slate-50 transition-colors group">
            <td class="py-4 px-6">
              <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                <span class="text-slate-400 group-hover:text-blue-400">#</span>NoBackseatGaming
              </div>
            </td>
            <td class="py-4 px-6">
              <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">System</span>
            </td>
            <td class="py-4 px-6 font-semibold text-slate-800">
              1,844 <span class="text-slate-400 font-normal text-sm">streams</span>
            </td>
            <td class="py-4 px-6">
              <div class="flex items-center gap-1 text-red-500 font-medium text-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0v-8m0 8l-8-8-4 4-6-6"></path></svg>
                -3%
              </div>
            </td>
            <td class="py-4 px-6 text-right">
              <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">Edit</button>
              <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">Delete</button>
            </td>
          </tr>

        </tbody>
      </table>
    </div>

    <div class="flex items-center justify-between mt-6 px-2 text-sm text-slate-500">
      <div>Showing 1 to 4 of 2,491 tags</div>
      <div class="flex gap-2">
        <button class="px-3 py-1 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50" disabled>Previous</button>
        <button class="px-3 py-1 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">Next</button>
      </div>
    </div>

  </div>
  """
end

  def access_tab(assigns) do
  ~H"""
  <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">

    <div class="flex justify-between items-center mb-8">
      <div>
        <h2 class="text-3xl font-bold text-slate-800 tracking-tight">Access Control</h2>
        <p class="text-slate-500 mt-1">Manage system roles, permissions, and security policies.</p>
      </div>
      <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
        + Create Role
      </button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">

      <div class="border border-red-200 bg-red-50/30 rounded-2xl p-6 relative overflow-hidden">
        <div class="absolute top-0 left-0 w-1 h-full bg-red-500"></div>

        <div class="flex justify-between items-start mb-6">
          <div>
            <div class="flex items-center gap-2 mb-1">
              <h3 class="font-bold text-xl text-slate-800">Super Admin</h3>
              <span class="bg-red-100 text-red-700 py-0.5 px-2 rounded-md text-xs font-bold uppercase tracking-wider">System</span>
            </div>
            <p class="text-sm text-slate-500">Unrestricted access to all Kameramani features and settings.</p>
          </div>
          <button class="text-slate-400 hover:text-red-600 font-medium text-sm transition-colors">Edit</button>
        </div>

        <div class="space-y-3 mb-6">
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Full System Configuration
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Manage Billing & Subscriptions
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Assign Admin Roles
          </div>
        </div>

        <div class="flex items-center justify-between border-t border-red-100 pt-4">
          <div class="flex -space-x-2">
            <div class="w-8 h-8 rounded-full bg-slate-300 border-2 border-white flex items-center justify-center text-xs font-bold text-white">E</div>
            <div class="w-8 h-8 rounded-full bg-slate-400 border-2 border-white flex items-center justify-center text-xs font-bold text-white">S</div>
          </div>
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">2</span> Accounts
          </div>
        </div>
      </div>

      <div class="border border-blue-200 bg-white rounded-2xl p-6 relative overflow-hidden hover:shadow-md transition-shadow">
        <div class="absolute top-0 left-0 w-1 h-full bg-blue-500"></div>

        <div class="flex justify-between items-start mb-6">
          <div>
            <div class="flex items-center gap-2 mb-1">
              <h3 class="font-bold text-xl text-slate-800">Global Moderator</h3>
              <span class="bg-blue-100 text-blue-700 py-0.5 px-2 rounded-md text-xs font-bold uppercase tracking-wider">Custom</span>
            </div>
            <p class="text-sm text-slate-500">Can moderate streams, chat, and handle user reports.</p>
          </div>
          <button class="text-slate-400 hover:text-blue-600 font-medium text-sm transition-colors">Edit</button>
        </div>

        <div class="space-y-3 mb-6">
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Ban / Suspend Users
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Force-close Active Streams
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-400">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            Cannot Access Billing
          </div>
        </div>

        <div class="flex items-center justify-between border-t border-gray-100 pt-4">
          <div class="flex -space-x-2">
            <div class="w-8 h-8 rounded-full bg-blue-300 border-2 border-white flex items-center justify-center text-xs font-bold text-white">M</div>
            <div class="w-8 h-8 rounded-full bg-blue-400 border-2 border-white flex items-center justify-center text-xs font-bold text-white">T</div>
            <div class="w-8 h-8 rounded-full bg-blue-200 border-2 border-white flex items-center justify-center text-xs font-bold text-white text-slate-600">+4</div>
          </div>
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">6</span> Accounts
          </div>
        </div>
      </div>

      <div class="border border-purple-200 bg-white rounded-2xl p-6 relative overflow-hidden hover:shadow-md transition-shadow">
        <div class="absolute top-0 left-0 w-1 h-full bg-purple-500"></div>

        <div class="flex justify-between items-start mb-6">
          <div>
            <div class="flex items-center gap-2 mb-1">
              <h3 class="font-bold text-xl text-slate-800">Partnered Streamer</h3>
              <span class="bg-purple-100 text-purple-700 py-0.5 px-2 rounded-md text-xs font-bold uppercase tracking-wider">System</span>
            </div>
            <p class="text-sm text-slate-500">Verified creators with monetization enabled.</p>
          </div>
          <button class="text-slate-400 hover:text-blue-600 font-medium text-sm transition-colors">Edit</button>
        </div>

        <div class="space-y-3 mb-6">
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Broadcast Video / Audio
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Receive Subscriptions & Tips
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Manage Channel Moderators
          </div>
        </div>

        <div class="flex items-center justify-between border-t border-gray-100 pt-4">
          <div class="flex -space-x-2">
            </div>
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">142</span> Accounts
          </div>
        </div>
      </div>

      <div class="border border-gray-200 bg-white rounded-2xl p-6 relative overflow-hidden hover:shadow-md transition-shadow">
        <div class="absolute top-0 left-0 w-1 h-full bg-gray-400"></div>

        <div class="flex justify-between items-start mb-6">
          <div>
            <div class="flex items-center gap-2 mb-1">
              <h3 class="font-bold text-xl text-slate-800">Standard User</h3>
              <span class="bg-gray-100 text-gray-700 py-0.5 px-2 rounded-md text-xs font-bold uppercase tracking-wider">System Default</span>
            </div>
            <p class="text-sm text-slate-500">The base permissions for all newly registered accounts.</p>
          </div>
          <button class="text-slate-400 hover:text-blue-600 font-medium text-sm transition-colors">Edit</button>
        </div>

        <div class="space-y-3 mb-6">
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Watch Streams
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-700">
            <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            Participate in Chat
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-400">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            Cannot Broadcast
          </div>
        </div>

        <div class="flex items-center justify-between border-t border-gray-100 pt-4">
          <div class="flex -space-x-2">
            </div>
          <div class="text-xs font-semibold text-slate-500">
            <span class="text-slate-800 font-bold">18,492</span> Accounts
          </div>
        </div>
      </div>

    </div>
  </div>
  """
end

  def settings_tab(assigns) do
  ~H"""
  <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">

    <div class="flex justify-between items-center mb-8">
      <div>
        <h2 class="text-3xl font-bold text-slate-800 tracking-tight">System Settings</h2>
        <p class="text-slate-500 mt-1">Configure global platform parameters for Kameramani.</p>
      </div>
      <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
        Save All Changes
      </button>
    </div>

    <div class="max-w-4xl space-y-8">

      <div class="border border-gray-200 rounded-2xl p-6 bg-slate-50/50">
        <h3 class="font-bold text-lg text-slate-800 mb-1">General Information</h3>
        <p class="text-sm text-slate-500 mb-6">Basic details and public-facing platform info.</p>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-semibold text-slate-700 mb-2">Platform Name</label>
            <input type="text" value="Kameramani" class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium" />
          </div>
          <div>
            <label class="block text-sm font-semibold text-slate-700 mb-2">Support Email Address</label>
            <input type="email" value="support@kameramani.com" class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium" />
          </div>
          <div class="md:col-span-2">
            <label class="block text-sm font-semibold text-slate-700 mb-2">Maintenance Mode</label>
            <div class="flex items-center gap-3 bg-white border border-gray-200 p-4 rounded-xl">
              <div class="w-11 h-6 bg-gray-200 rounded-full relative cursor-pointer">
                <div class="absolute left-1 top-1 bg-white w-4 h-4 rounded-full shadow-sm transition-transform"></div>
              </div>
              <div class="text-sm text-slate-600">
                <span class="font-bold text-slate-700">Offline</span> - Prevent non-admins from logging in.
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="border border-gray-200 rounded-2xl p-6 bg-slate-50/50">
        <h3 class="font-bold text-lg text-slate-800 mb-1">Video & Streaming Defaults</h3>
        <p class="text-sm text-slate-500 mb-6">Global limits and server configurations for broadcasts.</p>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="md:col-span-2">
            <label class="block text-sm font-semibold text-slate-700 mb-2">Primary Ingest Server (RTMP)</label>
            <div class="flex">
              <span class="inline-flex items-center px-4 rounded-l-xl border border-r-0 border-gray-200 bg-gray-100 text-slate-500 text-sm font-mono">
                rtmp://
              </span>
              <input type="text" value="ingest.kameramani.com/live" class="flex-1 px-4 py-2 bg-white border border-gray-200 rounded-r-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-mono text-sm" />
            </div>
          </div>
          <div>
            <label class="block text-sm font-semibold text-slate-700 mb-2">Max Bitrate (Standard Users)</label>
            <select class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium appearance-none">
              <option>4000 kbps (720p)</option>
              <option selected>6000 kbps (1080p)</option>
              <option>8000 kbps (1080p60)</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-semibold text-slate-700 mb-2">Max Bitrate (Partners)</label>
            <select class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium appearance-none">
              <option>6000 kbps (1080p)</option>
              <option selected>8000 kbps (1080p60)</option>
              <option>12000 kbps (1440p)</option>
            </select>
          </div>
        </div>
      </div>

      <div class="border border-red-200 rounded-2xl p-6 bg-white relative overflow-hidden">
        <div class="absolute top-0 left-0 w-1 h-full bg-red-500"></div>
        <h3 class="font-bold text-lg text-red-600 mb-1">Danger Zone</h3>
        <p class="text-sm text-slate-500 mb-6">Irreversible actions that affect the entire platform.</p>

        <div class="flex flex-col sm:flex-row gap-4">
          <button class="px-4 py-2 bg-white border border-red-200 text-red-600 font-semibold rounded-xl hover:bg-red-50 transition-colors">
            Clear Global Cache
          </button>
          <button class="px-4 py-2 bg-red-500 text-white font-semibold rounded-xl hover:bg-red-600 transition-colors">
            Force Logout All Users
          </button>
        </div>
      </div>

    </div>
  </div>
  """
end
  def overview(assigns)do
    ~H"""
    """
  end

  def category_tab(assigns) do
    ~H"""
    <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">
      <div class="flex justify-between items-center mb-8">
        <div>
          <h2 class="text-3xl font-bold text-slate-800 tracking-tight">Stream Categories</h2>
          <p class="text-slate-500 mt-1">
            Manage and organize the content classifications for Kameramani.
          </p>
        </div>
        <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
          + New Category
        </button>
      </div>

      <div class="flex gap-4 mb-8 border-b border-gray-100 pb-6">
        <div class="relative flex-1 max-w-md">
          <input
            type="text"
            placeholder="Search categories..."
            class="w-full pl-4 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700"
          />
        </div>
        <button class="px-4 py-2 bg-gray-50 border border-gray-200 text-slate-600 rounded-xl hover:bg-gray-100 font-medium transition-colors">
          Filter
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-purple-300 transition-all group bg-white relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-purple-500"></div>

          <div class="flex justify-between items-start mb-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center font-bold text-xl">
                🎮
              </div>
              <h3 class="font-bold text-xl text-slate-800 group-hover:text-purple-700 transition-colors">
                Gaming
              </h3>
            </div>
            <button class="text-slate-400 hover:text-slate-600">•••</button>
          </div>

          <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
            Live gameplay, esports tournaments, and gaming talk shows.
          </p>

          <div class="flex items-center justify-between border-t border-gray-100 pt-4">
            <div class="text-xs font-semibold text-slate-500">
              <span class="text-slate-800 font-bold">1,204</span> Active Streams
            </div>
            <div class="text-xs font-semibold text-purple-600 bg-purple-50 px-2 py-1 rounded-md">
              Popular
            </div>
          </div>
        </div>

        <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-blue-300 transition-all group bg-white relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-blue-500"></div>

          <div class="flex justify-between items-start mb-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xl">
                🎵
              </div>
              <h3 class="font-bold text-xl text-slate-800 group-hover:text-blue-700 transition-colors">
                Music & Audio
              </h3>
            </div>
            <button class="text-slate-400 hover:text-slate-600">•••</button>
          </div>

          <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
            Live DJ sets, acoustic performances, and music production.
          </p>

          <div class="flex items-center justify-between border-t border-gray-100 pt-4">
            <div class="text-xs font-semibold text-slate-500">
              <span class="text-slate-800 font-bold">452</span> Active Streams
            </div>
          </div>
        </div>

        <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-emerald-300 transition-all group bg-white relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-emerald-500"></div>

          <div class="flex justify-between items-start mb-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center font-bold text-xl">
                💻
              </div>
              <h3 class="font-bold text-xl text-slate-800 group-hover:text-emerald-700 transition-colors">
                Tech & Coding
              </h3>
            </div>
            <button class="text-slate-400 hover:text-slate-600">•••</button>
          </div>

          <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
            Software development, hardware building, and tech reviews.
          </p>

          <div class="flex items-center justify-between border-t border-gray-100 pt-4">
            <div class="text-xs font-semibold text-slate-500">
              <span class="text-slate-800 font-bold">128</span> Active Streams
            </div>
          </div>
        </div>

        <div class="border border-gray-200 rounded-2xl p-6 hover:shadow-lg hover:border-amber-300 transition-all group bg-white relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-amber-500"></div>

          <div class="flex justify-between items-start mb-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center font-bold text-xl">
                💬
              </div>
              <h3 class="font-bold text-xl text-slate-800 group-hover:text-amber-700 transition-colors">
                Just Chatting
              </h3>
            </div>
            <button class="text-slate-400 hover:text-slate-600">•••</button>
          </div>

          <p class="text-sm text-slate-500 mb-6 line-clamp-2 h-10">
            Casual conversations, Q&A sessions, and vlogging.
          </p>

          <div class="flex items-center justify-between border-t border-gray-100 pt-4">
            <div class="text-xs font-semibold text-slate-500">
              <span class="text-slate-800 font-bold">3,891</span> Active Streams
            </div>
            <div class="text-xs font-semibold text-amber-600 bg-amber-50 px-2 py-1 rounded-md">
              Trending
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def tag_tab(assigns) do
    ~H"""
    <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">
      <div class="flex justify-between items-center mb-8">
        <div>
          <h2 class="text-3xl font-bold text-slate-800 tracking-tight">Tag Management</h2>
          <p class="text-slate-500 mt-1">Monitor and moderate granular stream descriptors.</p>
        </div>
        <div class="flex gap-3">
          <button class="bg-white border border-gray-200 text-slate-700 hover:bg-gray-50 font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
            Merge Tags
          </button>
          <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
            + Create Tag
          </button>
        </div>
      </div>

      <div class="flex gap-4 mb-6">
        <div class="relative flex-1 max-w-md">
          <input
            type="text"
            placeholder="Search by tag name..."
            class="w-full pl-4 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700"
          />
        </div>
        <select class="px-4 py-2 bg-gray-50 border border-gray-200 text-slate-600 rounded-xl hover:bg-gray-100 font-medium transition-colors outline-none focus:ring-2 focus:ring-blue-500">
          <option>Sort by: Popularity</option>
          <option>Sort by: Newest</option>
          <option>Sort by: Name (A-Z)</option>
        </select>
      </div>

      <div class="overflow-hidden rounded-xl border border-gray-200">
        <table class="w-full text-left border-collapse bg-white">
          <thead class="bg-gray-50 text-slate-500 text-xs font-bold uppercase tracking-wider">
            <tr>
              <th class="py-4 px-6 border-b border-gray-200 w-1/3">Tag Name</th>
              <th class="py-4 px-6 border-b border-gray-200">Type</th>
              <th class="py-4 px-6 border-b border-gray-200">Current Usage</th>
              <th class="py-4 px-6 border-b border-gray-200">7-Day Trend</th>
              <th class="py-4 px-6 border-b border-gray-200 text-right">Actions</th>
            </tr>
          </thead>

          <tbody class="divide-y divide-gray-100 text-slate-700">
            <tr class="hover:bg-slate-50 transition-colors group">
              <td class="py-4 px-6">
                <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                  <span class="text-slate-400 group-hover:text-blue-400">#</span>Speedrun
                </div>
              </td>
              <td class="py-4 px-6">
                <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  System
                </span>
              </td>
              <td class="py-4 px-6 font-semibold text-slate-800">
                8,492 <span class="text-slate-400 font-normal text-sm">streams</span>
              </td>
              <td class="py-4 px-6">
                <div class="flex items-center gap-1 text-emerald-600 font-medium text-sm">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                    >
                    </path>
                  </svg>
                  +12%
                </div>
              </td>
              <td class="py-4 px-6 text-right">
                <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">
                  Edit
                </button>
                <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">
                  Delete
                </button>
              </td>
            </tr>

            <tr class="hover:bg-slate-50 transition-colors group">
              <td class="py-4 px-6">
                <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                  <span class="text-slate-400 group-hover:text-blue-400">#</span>AMA
                </div>
              </td>
              <td class="py-4 px-6">
                <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  User Created
                </span>
              </td>
              <td class="py-4 px-6 font-semibold text-slate-800">
                3,104 <span class="text-slate-400 font-normal text-sm">streams</span>
              </td>
              <td class="py-4 px-6">
                <div class="flex items-center gap-1 text-emerald-600 font-medium text-sm">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                    >
                    </path>
                  </svg>
                  +5%
                </div>
              </td>
              <td class="py-4 px-6 text-right">
                <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">
                  Edit
                </button>
                <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">
                  Delete
                </button>
              </td>
            </tr>

            <tr class="hover:bg-slate-50 transition-colors group">
              <td class="py-4 px-6">
                <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                  <span class="text-slate-400 group-hover:text-blue-400">#</span>Elixir
                </div>
              </td>
              <td class="py-4 px-6">
                <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  User Created
                </span>
              </td>
              <td class="py-4 px-6 font-semibold text-slate-800">
                412 <span class="text-slate-400 font-normal text-sm">streams</span>
              </td>
              <td class="py-4 px-6">
                <div class="flex items-center gap-1 text-slate-400 font-medium text-sm">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4">
                    </path>
                  </svg>
                  0%
                </div>
              </td>
              <td class="py-4 px-6 text-right">
                <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">
                  Edit
                </button>
                <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">
                  Delete
                </button>
              </td>
            </tr>

            <tr class="hover:bg-slate-50 transition-colors group">
              <td class="py-4 px-6">
                <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-800 font-medium group-hover:bg-blue-50 group-hover:text-blue-700 group-hover:border-blue-200 transition-colors">
                  <span class="text-slate-400 group-hover:text-blue-400">#</span>NoBackseatGaming
                </div>
              </td>
              <td class="py-4 px-6">
                <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  System
                </span>
              </td>
              <td class="py-4 px-6 font-semibold text-slate-800">
                1,844 <span class="text-slate-400 font-normal text-sm">streams</span>
              </td>
              <td class="py-4 px-6">
                <div class="flex items-center gap-1 text-red-500 font-medium text-sm">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 17h8m0 0v-8m0 8l-8-8-4 4-6-6"
                    >
                    </path>
                  </svg>
                  -3%
                </div>
              </td>
              <td class="py-4 px-6 text-right">
                <button class="text-slate-400 hover:text-blue-500 font-medium text-sm mr-4 transition-colors">
                  Edit
                </button>
                <button class="text-slate-400 hover:text-red-500 font-medium text-sm transition-colors">
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="flex items-center justify-between mt-6 px-2 text-sm text-slate-500">
        <div>Showing 1 to 4 of 2,491 tags</div>
        <div class="flex gap-2">
          <button
            class="px-3 py-1 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
            disabled
          >
            Previous
          </button>
          <button class="px-3 py-1 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
            Next
          </button>
        </div>
      </div>
    </div>
    """
  end

  def access_tab(assigns) do
    ~H"""
    <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">
      <div class="flex justify-between items-center mb-8">
        <div>
          <h2 class="text-3xl font-bold text-slate-800 tracking-tight">Access Control</h2>
          <p class="text-slate-500 mt-1">Manage system roles, permissions, and security policies.</p>
        </div>
        <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
          + Create Role
        </button>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="border border-red-200 bg-red-50/30 rounded-2xl p-6 relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-red-500"></div>

          <div class="flex justify-between items-start mb-6">
            <div>
              <div class="flex items-center gap-2 mb-1">
                <h3 class="font-bold text-xl text-slate-800">Super Admin</h3>
                <span class="bg-red-100 text-red-700 py-0.5 px-2 rounded-md text-xs font-bold uppercase tracking-wider">
                  System
                </span>
              </div>
              <p class="text-sm text-slate-500">
                Unrestricted access to all Kameramani features and settings.
              </p>
            </div>
            <button class="text-slate-400 hover:text-red-600 font-medium text-sm transition-colors">
              Edit
            </button>
          </div>

          <div class="space-y-3 mb-6">
            <div class="flex items-center gap-2 text-sm text-slate-700">
              <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
              Full System Configuration
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-700">
              <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
              Manage Billing & Subscriptions
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-700">
              <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
              Assign Admin Roles
            </div>
          </div>

          <div class="flex items-center justify-between border-t border-red-100 pt-4">
            <div class="flex -space-x-2">
              <div class="w-8 h-8 rounded-full bg-slate-300 border-2 border-white flex items-center justify-center text-xs font-bold text-white">
                E
              </div>
              <div class="w-8 h-8 rounded-full bg-slate-400 border-2 border-white flex items-center justify-center text-xs font-bold text-white">
                S
              </div>
            </div>
            <div class="text-xs font-semibold text-slate-500">
              <span class="text-slate-800 font-bold">2</span> Accounts
            </div>
          </div>
        </div>

        <div class="border border-blue-200 bg-white rounded-2xl p-6 relative overflow-hidden hover:shadow-md transition-shadow">
          <div class="absolute top-0 left-0 w-1 h-full bg-blue-500"></div>

          <div class="flex justify-between items-start mb-6">
            <div>
              <div class="flex items-center gap-2 mb-1">
                <h3 class="font-bold text-xl text-slate-800">Global Moderator</h3>
                <span class="bg-blue-100 text-blue-700 py-0.5 px-2 rounded-md text-xs font-bold uppercase tracking-wider">
                  Custom
                </span>
              </div>
              <p class="text-sm text-slate-500">
                Can moderate streams, chat, and handle user reports.
              </p>
            </div>
            <button class="text-slate-400 hover:text-blue-600 font-medium text-sm transition-colors">
              Edit
            </button>
          </div>

          <div class="space-y-3 mb-6">
            <div class="flex items-center gap-2 text-sm text-slate-700">
              <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
              Ban / Suspend Users
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-700">
              <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
              Force-close Active Streams
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-400">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                >
                </path>
              </svg>
              Cannot Access Billing
            </div>
          </div>

          <div class="flex items-center justify-between border-t border-gray-100 pt-4">
            <div class="flex -space-x-2">
              <div class="w-8 h-8 rounded-full bg-blue-300 border-2 border-white flex items-center justify-center text-xs font-bold text-white">
                M
              </div>
              <div class="w-8 h-8 rounded-full bg-blue-400 border-2 border-white flex items-center justify-center text-xs font-bold text-white">
                T
              </div>
              <div class="w-8 h-8 rounded-full bg-blue-200 border-2 border-white flex items-center justify-center text-xs font-bold text-white text-slate-600">
                +4
              </div>
            </div>
            <div class="text-xs font-semibold text-slate-500">
              <span class="text-slate-800 font-bold">6</span> Accounts
            </div>
          </div>
        </div>



        <div class="border border-gray-200 bg-white rounded-2xl p-6 relative overflow-hidden hover:shadow-md transition-shadow">
          <div class="absolute top-0 left-0 w-1 h-full bg-gray-400"></div>

          <div class="flex justify-between items-start mb-6">
            <div>
              <div class="flex items-center gap-2 mb-1">
                <h3 class="font-bold text-xl text-slate-800">Standard User</h3>
                <span class="bg-gray-100 text-gray-700 py-0.5 px-2 rounded-md text-xs font-bold uppercase tracking-wider">
                  System Default
                </span>
              </div>
              <p class="text-sm text-slate-500">
                The base permissions for all newly registered accounts.
              </p>
            </div>
            <button class="text-slate-400 hover:text-blue-600 font-medium text-sm transition-colors">
              Edit
            </button>
          </div>

          <div class="space-y-3 mb-6">
            <div class="flex items-center gap-2 text-sm text-slate-700">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
              Watch Streams
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-700">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
              Participate in Chat
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-400">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                >
                </path>
              </svg>
              Cannot Broadcast
            </div>
          </div>

          <div class="flex items-center justify-between border-t border-gray-100 pt-4">
            <div class="flex -space-x-2"></div>
            <div class="text-xs font-semibold text-slate-500">
              <span class="text-slate-800 font-bold">18,492</span> Accounts
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def settings_tab(assigns) do
    ~H"""
    <div class="col-span-5 bg-white rounded-3xl shadow-sm border border-white/50 p-8 min-h-full">
      <div class="flex justify-between items-center mb-8">
        <div>
          <h2 class="text-3xl font-bold text-slate-800 tracking-tight">System Settings</h2>
          <p class="text-slate-500 mt-1">Configure global platform parameters for Kameramani.</p>
        </div>
        <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded-full transition-colors shadow-sm">
          Save All Changes
        </button>
      </div>

      <div class="max-w-4xl space-y-8">
        <div class="border border-gray-200 rounded-2xl p-6 bg-slate-50/50">
          <h3 class="font-bold text-lg text-slate-800 mb-1">General Information</h3>
          <p class="text-sm text-slate-500 mb-6">Basic details and public-facing platform info.</p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-semibold text-slate-700 mb-2">Platform Name</label>
              <input
                type="text"
                value="Kameramani"
                class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium"
              />
            </div>
            <div>
              <label class="block text-sm font-semibold text-slate-700 mb-2">
                Support Email Address
              </label>
              <input
                type="email"
                value="support@kameramani.com"
                class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm font-semibold text-slate-700 mb-2">Maintenance Mode</label>
              <div class="flex items-center gap-3 bg-white border border-gray-200 p-4 rounded-xl">
                <div class="w-11 h-6 bg-gray-200 rounded-full relative cursor-pointer">
                  <div class="absolute left-1 top-1 bg-white w-4 h-4 rounded-full shadow-sm transition-transform">
                  </div>
                </div>
                <div class="text-sm text-slate-600">
                  <span class="font-bold text-slate-700">Offline</span>
                  - Prevent non-admins from logging in.
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="border border-gray-200 rounded-2xl p-6 bg-slate-50/50">
          <h3 class="font-bold text-lg text-slate-800 mb-1">Video & Streaming Defaults</h3>
          <p class="text-sm text-slate-500 mb-6">
            Global limits and server configurations for broadcasts.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="md:col-span-2">
              <label class="block text-sm font-semibold text-slate-700 mb-2">
                Primary Ingest Server (RTMP)
              </label>
              <div class="flex">
                <span class="inline-flex items-center px-4 rounded-l-xl border border-r-0 border-gray-200 bg-gray-100 text-slate-500 text-sm font-mono">
                  rtmp://
                </span>
                <input
                  type="text"
                  value="ingest.kameramani.com/live"
                  class="flex-1 px-4 py-2 bg-white border border-gray-200 rounded-r-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-mono text-sm"
                />
              </div>
            </div>
            <div>
              <label class="block text-sm font-semibold text-slate-700 mb-2">
                Max Bitrate (Standard Users)
              </label>
              <select class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium appearance-none">
                <option>4000 kbps (720p)</option>
                <option selected>6000 kbps (1080p)</option>
                <option>8000 kbps (1080p60)</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-semibold text-slate-700 mb-2">
                Max Bitrate (Partners)
              </label>
              <select class="w-full px-4 py-2 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700 font-medium appearance-none">
                <option>6000 kbps (1080p)</option>
                <option selected>8000 kbps (1080p60)</option>
                <option>12000 kbps (1440p)</option>
              </select>
            </div>
          </div>
        </div>

        <div class="border border-red-200 rounded-2xl p-6 bg-white relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-red-500"></div>
          <h3 class="font-bold text-lg text-red-600 mb-1">Danger Zone</h3>
          <p class="text-sm text-slate-500 mb-6">
            Irreversible actions that affect the entire platform.
          </p>

          <div class="flex flex-col sm:flex-row gap-4">
            <button class="px-4 py-2 bg-white border border-red-200 text-red-600 font-semibold rounded-xl hover:bg-red-50 transition-colors">
              Clear Global Cache
            </button>
            <button class="px-4 py-2 bg-red-500 text-white font-semibold rounded-xl hover:bg-red-600 transition-colors">
              Force Logout All Users
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def overview(assigns) do
    ~H"""
    """
  end
end
