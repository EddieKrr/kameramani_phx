defmodule KameramaniPhxWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use KameramaniPhxWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

def app(assigns) do
  ~H"""
  <header class="navbar bg-[#0e0e10] border-b border-white/5 px-4 h-16 flex items-center justify-between sticky top-0 z-50">
    <div class="flex items-center gap-4">
      <.link href="/" class="flex items-center gap-2 text-indigo-500 hover:text-indigo-400 transition-colors">
        <div class="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center shadow-lg shadow-indigo-500/20">
          <.icon name="hero-bolt-solid" class="h-5 w-5 text-white" />
        </div>
        <span class="text-xl font-black tracking-tighter italic">Kameramani</span>
      </.link>
    </div>

    <div class="hidden md:flex flex-1 justify-center max-w-md px-4">
      <div class="relative w-full group">
        <input
          type="text"
          placeholder="Search streams..."
          class="w-full bg-[#18181b] border border-transparent focus:border-indigo-500/50 text-white pl-10 pr-4 py-1.5 rounded-lg focus:outline-none focus:ring-1 focus:ring-indigo-500/50 placeholder-gray-500 transition-all"
        />
        <.icon name="hero-magnifying-glass" class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-500 group-focus-within:text-indigo-400" />
      </div>
    </div>

    <div class="flex items-center gap-2 sm:gap-4">
      <button class="md:hidden p-2 text-gray-400 hover:text-white">
        <.icon name="hero-magnifying-glass" class="h-6 w-6" />
      </button>

      <%= if @current_scope && @current_scope.user do %>
        <div class="flex items-center gap-3">
          <span class="hidden sm:block text-xs font-bold text-gray-400 uppercase tracking-widest">
            <span class="text-indigo-500"><%= @current_scope.user.username %></span>
          </span>

          <div class="relative group">
            <button class="w-9 h-9 md:w-10 md:h-10 bg-indigo-600 rounded-full flex items-center justify-center text-white font-black border-2 border-transparent group-hover:border-indigo-500 transition-all">
              <%= String.first(@current_scope.user.username || "U") |> String.upcase() %>
            </button>

            <div class="absolute right-0 top-full mt-2 w-48 bg-[#18181b] border border-white/10 rounded-xl shadow-2xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 overflow-hidden">
              <div class="py-1">
                <.link navigate={~p"/users/settings"} class="flex items-center gap-2 px-4 py-2.5 text-sm text-gray-300 hover:bg-white/5 hover:text-white transition-colors">
                  <.icon name="hero-user" class="w-4 h-4" /> Settings
                </.link>
                <div class="border-t border-white/5 my-1"></div>
                <.link href={~p"/users/log-out"} method="delete" class="flex items-center gap-2 px-4 py-2.5 text-sm text-red-400 hover:bg-red-500/10 transition-colors">
                  <.icon name="hero-arrow-right-on-rectangle" class="w-4 h-4" /> Log Out
                </.link>
              </div>
            </div>
          </div>
        </div>
      <% else %>
        <.link
          navigate={~p"/auth"}
          class="bg-indigo-600 hover:bg-indigo-500 text-white px-4 py-2 rounded-lg text-xs md:text-sm font-bold transition-all active:scale-95"
        >
          Sign In
        </.link>
      <% end %>
    </div>
  </header>

  <main class="w-full">
    {render_slot(@inner_block)}
  </main>

  <.flash_group flash={@flash} />
  """
end

  @doc """
  Renders auth layout without navbar for login/register pages.

  ## Examples

      <Layouts.auth flash={@flash}>
        <h1>Auth Content</h1>
      </Layouts.auth>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def auth(assigns) do
    ~H"""
    <main class="h-screen w-full">
      {@inner_content}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
