defmodule KameramaniPhxWeb.NavbarSearchComponent do
  use KameramaniPhxWeb, :live_component
  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Streaming

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:current_user, assigns.current_user)
     |> assign_new(:search_form, fn -> to_form(%{"query" => ""}, as: :search) end)
     |> assign_new(:results, fn -> [] end)
     |> assign_new(:query, fn -> "" end)
     |> assign_new(:live_user_ids, fn -> MapSet.new() end)}
  end

  def handle_event("search_username", %{"search" => %{"query" => query}}, socket) do
    query = String.trim(query)

    results =
      if query == "" do
        []
      else
        Accounts.list_users_by_username(socket.assigns.current_user, query)
      end

    live_user_ids =
      if query == "" do
        MapSet.new()
      else
        query
        |> Streaming.list_live_streams_by_username()
        |> Enum.map(& &1.user_id)
        |> MapSet.new()
      end

    {:noreply,
     socket
     |> assign(results: results, query: query, live_user_ids: live_user_ids)
     |> assign(search_form: to_form(%{"query" => query}, as: :search))}
  end

  def render(assigns) do
    ~H"""
    <div class="relative" id="navbar-search-root">
      <.form
        for={@search_form}
        id="navbar-search-form"
        phx-change="search_username"
        phx-submit="search_username"
        phx-target={@myself}
      >
        <.input
          field={@search_form[:query]}
          type="text"
          placeholder="Search streamers..."
          autocomplete="off"
          class="bg-slate-700 text-white px-4 py-2 rounded-full w-64 focus:outline-none focus:ring-2 focus:ring-blue-500 placeholder-slate-400"
        />
      </.form>

      <%= if @query != "" do %>
        <div class="absolute left-0 right-0 mt-2 rounded-xl border border-slate-700 bg-slate-800/95 backdrop-blur shadow-xl z-50 overflow-hidden">
          <%= if @results == [] do %>
            <div class="px-4 py-3 text-sm text-slate-300" id="navbar-search-empty">
              No live streamers found.
            </div>
          <% else %>
            <div class="flex flex-col" id="navbar-search-results">
              <.link
                :for={user <- @results}
                navigate={
                  if(MapSet.member?(@live_user_ids, user.id),
                    do: ~p"/watch/#{user.username}",
                    else: ~p"/users/profile/#{user.username}"
                  )
                }
                class="flex items-center gap-3 px-4 py-3 text-sm text-white hover:bg-slate-700/70 transition-colors"
                id={"navbar-search-item-#{user.id}"}
              >
                <%= if user.profile_picture do %>
                  <img
                    src={user.profile_picture}
                    alt="{user.username}'s Avatar"
                    class="w-8 h-8 rounded-full object-cover border-2 border-slate-600"
                  />
                <% else %>
                  <div class="w-8 h-8 bg-slate-600 rounded-full flex items-center justify-center text-sm text-white font-semibold">
                    {String.first(user.username || "U") |> String.upcase()}
                  </div>
                <% end %>
                <div class="flex flex-col leading-tight">
                  <span class="font-semibold">{user.username}</span>
                  <span class="text-xs text-slate-300 truncate max-w-[14rem]">{user.bio}</span>
                </div>
                <%= if MapSet.member?(@live_user_ids, user.id) do %>
                  <span class="ml-auto inline-flex items-center gap-1 rounded-full bg-red-500/90 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-white">
                    <.icon name="hero-signal" class="h-3 w-3" /> Live
                  </span>
                <% else %>
                  <span class="ml-auto inline-flex items-center gap-1 rounded-full bg-gray-500/90 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-white">
                    Offline
                  </span>
                <% end %>
              </.link>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
