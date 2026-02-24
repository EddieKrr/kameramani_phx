defmodule KameramaniPhxWeb.ProfileComponents do
  import KameramaniPhxWeb.CoreComponents
  use Phoenix.Component


  def profile_header(assigns) do
    ~H"""
    <%= if @is_live? do %>
    <div class="aspect-video">
      
    </div>
    <%else%>
    <div class="aspect-video">
      <div class="absolute inset-0 bg-indigo-500 blur-2xl opacity-20 animate-pulse">
        <.svg variant="camera-slash" />
      </div>
    </div>

    <%end%>
    """
  end

  def about_section(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div>Home</div>
      <div>About</div>
      <div>Contact</div>
    </div>
    """
  end
end
