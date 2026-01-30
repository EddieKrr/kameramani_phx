defmodule KameramaniPhxWeb.SidebarComponents do
  use Phoenix.Component
  use Gettext, backend: KameramaniPhxWeb.Gettext


  attr :name, :string, required: true
  attr :game, :string
  attr :viewer_count, :integer
  attr :src, :string

  def sidebar_item(assigns) do
    ~H"""
    <div class="flex flex-row items-center gap-3 hover:bg-green-400 hover:rounded-full hover:p-2">
      <img src={@src} class="rounded-full h-12 w-12 object-contain">
      <div class="flex-col flex-1">
        <div class="flex-col">
          <div class="text-base font-bold text-white">{@name}</div>
          <div class="text-sm text-gray-500 truncate">{@game}</div>
        </div>
      </div>
      <span class="justify-end">{@viewer_count}</span>
    </div>
    """
  end
end
