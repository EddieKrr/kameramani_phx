defmodule KameramaniPhxWeb.CardComponents do
  use KameramaniPhxWeb, :html

  attr :stream_name, :string, required: true
  attr :streamer, :string, required: true
  attr :category, :string, required: true
  attr :tags, :string, required: true
  attr :viewer_count, :integer, required: true
  attr :avatar, :string, default: "https://ui-avatars.com/api/?background=random"
  attr :id, :integer, required: true

  def card(assigns) do
    ~H"""
    <.link patch={~p"/watch/#{@streamer}"}>
      <article>
        <div class="relative aspect-video w-full bg-gradient-to-tl from-black to-slate-700 hover:scale-105 hover:z-50 hover:shadow-2xl transition-all duration-300 ease-in-out rounded-lg">
          <div class="absolute top-1 left-1 px-1 text-red-600 text-xs">LIVE</div>

          <div class="absolute flex bottom-1 right-1 bg-black/60 rounded-full text-xs px-1 text-white">
            <.svg variant="eye" class="h-4 w-4 text-white mb-[0.3rem] mx-1" />{@viewer_count}
          </div>
        </div>

        <div class="flex flex-row gap-3">
          <img class="h-10 w-10 rounded-full" alt={@streamer} src={@avatar} />
          <div class="flex flex-col min-w-0">
            <div class="font-bold text-white truncate">{@stream_name}</div>

            <div class="text-gray-400 text-sm">{@streamer}</div>

            <div class="text-gray-400 text-sm">{@tags}</div>

            <div class="bg-gray-700 text-xs text-gray-300 rounded-full px-2 w-fit">{@category}</div>
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
