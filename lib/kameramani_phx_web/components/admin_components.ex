defmodule KameramaniPhxWeb.AdminComponents do
  use Phoenix.Component


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
        <.link patch={@item.path} class="block bg-blue-200 pl-6 py-3 rounded-l-full text-blue-900 font-bold relative z-10">
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

  def user_tab (assigns) do
    ~H"""
    <div>
    <div class="col-start-2 col-span-2 glass-pane">
      Questions
    </div>
    <div class="col-start-5">
      Questions
    </div>
    <div class="col-start-2 col-span-2 glass-pane">
      Questions
    </div>
    </div>
    """
  end

  def category_tab(assigns) do
    ~H"""
    <div>
      <h2> This is the Categories Tab </h2>
    </div>
    """
  end

  def tag_tab(assigns) do
    ~H"""
    <div>
      <h2> This is the Tags Tab </h2>
    </div>
    """
  end

  def access_tab(assigns) do
    ~H"""
    <div>
      <h2> This is the Access Control Tab </h2>
    </div>
    """
  end

  def settings_tab(assigns) do
    ~H"""
    <div>
      <h2> This is the Settings Tab </h2>
    </div>
    """
  end
  def overview(assigns)do
    ~H"""
    """
  end

end
