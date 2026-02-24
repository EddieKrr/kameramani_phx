defmodule KameramaniPhxWeb.SidebarComponents do
  use Phoenix.Component

  attr :name, :string, required: true
  attr :game, :string
  attr :viewer_count, :string
  attr :src, :string, default: "https://i.pravatar.cc/150?img=1"
  attr :active, :boolean, default: false
  attr :show_details, :boolean, default: true

  def sidebar_item(assigns) do
    ~H"""
    <div class={[
      "flex flex-row items-center mb-1 transition-all ease-in-out duration-300 p-1 cursor-pointer",
      "hover:bg-white/10 hover:rounded-lg",
      @active && "bg-white/5 border-l-2 border-indigo-500 rounded-r-lg"
    ]}>
      <div class="relative shrink-0">
        <img src={@src} class="rounded-full h-8 w-8 object-cover" />
        <%= if !@show_details do %>
           <div class="absolute -top-1 -right-1 w-2 h-2 bg-red-600 rounded-full border border-[#18181b]"></div>
        <% end %>
      </div>
      
      <%= if @show_details do %>
        <div class="flex flex-col flex-1 min-w-0 mx-3">
          <div class="text-sm font-bold text-[#efeff1] truncate">{@name}</div>
          <div class="text-[11px] text-[#adadb8] truncate">{@game}</div>
        </div>

        <div class="flex items-center gap-1 text-[#efeff1] text-xs">
          <div class="w-1.5 h-1.5 bg-red-600 rounded-full"></div>
          {@viewer_count}
        </div>
      <% end %>
    </div>
    """
  end
end
