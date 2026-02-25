defmodule KameramaniPhxWeb.CardComponents do
  use KameramaniPhxWeb, :html

  attr :stream_name, :string, required: true
  attr :streamer, :string, required: true
  attr :category, :string, required: true
  attr :tags, :list, default: []
  attr :viewer_count, :integer, required: true
  attr :avatar, :string, default: "https://ui-avatars.com/api/?background=random"
  attr :id, :any, required: true
  attr :is_live, :boolean, default: false

  def card(assigns) do
    ~H"""
    <.link navigate={~p"/watch/#{@streamer}"} class="group block">
      <article>
        <div class="relative aspect-video w-full bg-gradient-to-tl from-black to-slate-700 group-hover:scale-[1.03] group-hover:z-50 group-hover:shadow-2xl transition-all duration-300 ease-in-out rounded-lg overflow-hidden">
          <%= if @is_live do %>
            <div class="absolute top-2 left-2 bg-red-600 text-white font-black text-[10px] px-2 py-0.5 rounded shadow-lg">
              LIVE
            </div>
          <% end %>

          <div class="absolute flex bottom-1 right-1 bg-black/60 rounded-full text-xs px-1">
            <.svg variant="eye" class="h-4 w-4 mb-[0.3rem] mx-1" />{@viewer_count}
          </div>
        </div>

        <div class="flex flex-row gap-3 mt-3">
          <img class="h-10 w-10 rounded-full" alt={@streamer} src={@avatar} />
          <div class="flex flex-col min-w-0">
            <div class="font-bold text-white truncate group-hover:text-blue-300 transition-colors">
              {@stream_name}
            </div>

            <div class="text-gray-400 text-sm">{@streamer}</div>

            <div class="flex flex-wrap items-center gap-1.5 mt-2">
              <%= for tag <- @tags do %>
                <span class="text-[11px] uppercase tracking-widest font-semibold px-2.5 py-0.5 rounded-full bg-[#0f172a] text-[#7dd3fc] border border-[#0ea5e9]/30">
                  {tag}
                </span>
              <% end %>
            </div>

            <span class="mt-2 text-[11px] font-semibold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-[#1f2937] text-[#fbbf24] border border-[#fbbf24]/30 w-fit">
              {@category}
            </span>
          </div>
        </div>
      </article>
    </.link>
    """
  end

  attr :name, :string, required: true
  attr :slug, :string, required: true
  attr :viewers, :integer, required: true
  attr :box_art, :string, default: "https://placehold.co/400x533/4c1d95/ffffff?text=Game+Art"

  def category_card(assigns) do
    ~H"""
    <.link navigate={~p"/directory/#{@slug}"}>
      <div class="grid grid-cols-5">
        <div>
          <img src={@box_art} />
          <div>{@name}</div>
          <div>{@viewers}</div>
          <div>{@slug}</div>
        </div>
      </div>
    </.link>
    """
  end
end
