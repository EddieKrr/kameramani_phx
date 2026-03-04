defmodule KameramaniPhxWeb.CardComponents do
  use KameramaniPhxWeb, :html

  attr :stream_name, :string, required: true
  attr :streamer, :string, required: true
  attr :category, :string, required: true
  attr :category_slug, :string, default: nil
  attr :tags, :list, default: []
  attr :viewer_count, :integer, required: true
  attr :avatar, :string, default: "https://ui-avatars.com/api/?background=random"
  attr :id, :any, required: true
  attr :is_live, :boolean, default: false
  attr :thumbnail_url, :string, default: nil

  def card(assigns) do
    ~H"""
    <article class="">
      <.link navigate={~p"/watch/#{@streamer}"} class="group block">
        <div class="relative w-full bg-gradient-to-tl from-black to-slate-700 group-hover:scale-[1.03] group-hover:z-50 group-hover:shadow-2xl transition-all duration-300 ease-in-out rounded-lg overflow-hidden">
          <%= if @thumbnail_url do %>
            <img
              src={@thumbnail_url}
              alt={"#{@streamer} stream thumbnail"}
              class="h-full w-full object-cover"
              loading="lazy"
            />
          <% else %>
            <div class="flex h-full w-full items-center justify-center text-sm text-white/70">
              Stream offline
            </div>
          <% end %>
          <%= if @is_live do %>
            <div class="absolute top-2 left-2 bg-red-600 text-white font-black text-[10px] px-2 py-0.5 rounded shadow-lg">
              LIVE
            </div>
          <% end %>

          <div class="absolute flex bottom-1 right-1 bg-black/60 rounded-full text-xs px-1">
            <.svg variant="eye" class="h-4 w-4 mb-[0.3rem] mx-1" />{@viewer_count}
          </div>
        </div>
      </.link>
      <div class="flex flex-row gap-3 mt-3 rounded-lg p-4">
        <img class="h-10 w-10 rounded-full" alt={@streamer} src={@avatar} />
        <div class="flex flex-col min-w-0">
          <div class="font-bold text-white truncate group-hover:text-blue-300 transition-colors">
            {@stream_name}
          </div>

          <div class="text-gray-400 text-sm">{@streamer}</div>
          <.link
            navigate={~p"/directory/#{resolve_category_slug(@category_slug, @category)}"}
            class="self-start"
          >
            <span class="text-[#bf94ff] hover:underline cursor-pointer font-semibold text-sm">
              {@category}
            </span>
          </.link>

          <div class="flex flex-wrap items-center gap-1.5 mt-2">
            <%= for tag <- @tags do %>
              <span class="bg-[#26262c] hover:bg-[#323239] transition-colors cursor-pointer text-[#adadb8] font-semibold text-[12px] px-3 py-0.5 rounded-full">
                {tag}
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </article>
    """
  end

  attr :name, :string, required: true
  attr :slug, :string, required: true

  attr :thumbnail_url, :string,
    default: "https://placehold.co/400x533/4c1d95/ffffff?text=Game+Art"

  def category_card(assigns) do
    ~H"""
    <article class="group">
      <div class="relative aspect-[3/4] overflow-hidden rounded-xl bg-[#15131a] border border-white/5 shadow-[0_10px_30px_rgba(0,0,0,0.45)]">
        <img
          src={@thumbnail_url}
          alt={@name}
          class="h-full w-full object-cover transition-transform duration-500 ease-out group-hover:scale-[1.06]"
          loading="lazy"
        />
        <div class="absolute inset-x-0 bottom-0 h-20 bg-gradient-to-t from-black/80 via-black/40 to-transparent">
        </div>
        <div class="absolute bottom-2 left-2 right-2 flex items-center justify-between">
          <span class="rounded-full bg-black/60 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-wider text-white/90 border border-white/10">
            {@slug}
          </span>
        </div>
      </div>
      <div class="mt-3">
        <div class="text-sm font-semibold text-white group-hover:text-[#7cf6ff] transition-colors">
          {@name}
        </div>
      </div>
    </article>
    """
  end

  defp resolve_category_slug(category_slug, _category_name) when is_binary(category_slug) do
    String.trim(category_slug)
  end

  defp resolve_category_slug(_category_slug, category_name) when is_binary(category_name) do
    category_name
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp resolve_category_slug(_category_slug, _category_name), do: "just-chatting"
end
