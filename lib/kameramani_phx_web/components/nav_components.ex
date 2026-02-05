defmodule KameramaniPhxWeb.NavComponents do
  use KameramaniPhxWeb, :html


  attr :current_user, :any, required: true
  attr :layout, :atom, values: [:floating, :fixed], default: :fixed

  def navbar(assigns) do
    ~H"""
      <div class={nav_classes(@layout)}>
        <%= if @current_user do %>
         <div class="text-blue-500" >Kameramani</div>
         <div class="border-2 border-gray-700 text-gray-700">Search</div>
         <img alt={@name} src={@src} class="rounded-full h-12 w-12 object-contain"/>
        <% else %>
         <div class="text-blue-500" >Kameramani</div>
         <div class="border-2 border-gray-700 text-gray-700/">Search</div>
         <div><.link patch={~p"/register"}>Sign In/Register</.link></div>
        <% end %>
      </div>
    """
end
  defp nav_classes(:floating) do
    "flex items-center justify-between px-6 sticky top-0 z-50 w-3/4 h-12 rounded-full bg-gray-700/50 mx-auto shadow-2xl backdrop-blur"
  end
  defp nav_classes(:fixed) do
    "flex flex-row justify-between z-50 w-full h-12 bg-gray-700"
  end
end
