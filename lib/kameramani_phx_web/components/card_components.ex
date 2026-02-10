defmodule KameramaniPhxWeb.CardComponents do
  use KameramaniPhxWeb, :html

  attr :game, :string, required: true
  attr :streamer, :string, required: true
  attr :category, :string, required: true
  attr :genre, :string, required: true
  attr :viewer_count, :integer, required: true
  attr :avatar, :string, default: "https://ui-avatars.com/api/?background=random"
  attr :id, :any, required: true

  def card(assigns) do
    ~H"""
    <.link patch={~p"/watch/#{@id}"}>
      <article>
        <div class="relative aspect-video w-full bg-gradient-to-tl from-black to-slate-700 hover:scale-110 hover:z-50 hover:shadow-2xl transition-all duration-300 ease-in-out rounded-lg">
          <div class="absolute top-1 left-1 px-1 text-red-600 text-xs">LIVE</div>

          <div class="absolute bottom-1 right-1 bg-black/60 rounded-full text-xs px-1">
            <.icon class="h-4 w-4 text-white mb-[0.3rem] mx-1" name="hero-eye" />{@viewer_count}
          </div>
        </div>

        <div class="flex flex-row gap-3">
          <img class="h-10 w-10 rounded-full" alt={@streamer} src={@avatar} />
          <div class="flex flex-col min-w-0">
            <div class="font-bold text-white truncate">{@game}</div>

            <div class="text-gray-400 text-sm">{@streamer}</div>

            <div class="text-gray-400 text-sm">{@genre}</div>

            <div class="bg-gray-700 text-xs text-gray-300 rounded-full px-2 w-fit">{@category}</div>
          </div>
        </div>
      </article>
    </.link>
    """
  end
end
