defmodule KameramaniPhxWeb.SidebarComponents do
  use Phoenix.Component

  attr :name, :string, required: true
  attr :game, :string
  attr :viewer_count, :integer
  attr :src, :string

  def sidebar_item(assigns) do
    ~H"""
    <div class="flex flex-row items-center mb-1 transition-all ease-in-out duration-300 hover:backdrop-blur hover:rounded-2xl hover:scale-105 hover:z-10 hover:border hover:border-indigo-300/90">
      <img src={@src} class="rounded-full h-12 w-12 object-contain">
      <div class="flex-col flex-1 p-1">
        <div class="flex-col">
          <div class="text-base font-bold">{@name}</div>
          <div class="text-sm  truncate">{@game}</div>
        </div>
      </div>
      <div class="justify-end"><!--<.icon class="h-2 w-3" name="hero-eye"/>--> {@viewer_count}</div>
    </div>
    """
  end
end
