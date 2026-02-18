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

  attr :current_user, :map,
    default: nil,
    doc: "the current [user](https://hexdocs.pm/phoenix/users.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="mx-auto max-w-[1440px] navbar fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-4 sm:px-6 lg:px-8">
      <div class="mx-4 flex items-center gap-4 justify-between w-full px-4 sm:px-6 py-2 rounded-xl bg-slate-800/60 backdrop-blur-sm border-2 mt-3 border-slate-700">
        <div class="flex">
          <.link
            href="/"
            class="flex items-center gap-2 text-blue-400 hover:text-blue-300 transition-colors"
          >
            <span class="text-lg font-bold tracking-tighter text-lg uppercase italic">
              Kameramani
            </span>
          </.link>
        </div>

        <%= if @current_user do %>
          <div class="flex items-center gap-6">
            <div class="relative">
              <input
                type="text"
                placeholder="Search streams..."
                class="bg-slate-700 text-white px-4 py-2 rounded-full w-64 focus:outline-none focus:ring-2 focus:ring-blue-500 placeholder-slate-400"
              />
            </div>
            <div class="flex items-center gap-3">
              <span class="text-white">
                Welcome,
                <span class="font-semibold text-blue-400 capitalize">
                  {Map.get(@current_user, :user, @current_user).username}
                </span>
              </span>
              <div class="relative group cursor-pointer">
                <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                  {String.first(Map.get(@current_user, :user, @current_user).username || "U")
                  |> String.upcase()}
                </div>

                <div class="absolute right-0 top-full mt-2 w-48 bg-slate-700 rounded-lg shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50">
                  <div class="py-2">
                    <.link
                      navigate={
                        ~p"/users/profile/#{Map.get(@current_user, :user, @current_user).username}"
                      }
                      class="flex items-center gap-2 px-4 py-2 text-white hover:bg-slate-600 transition colors"
                    >
                      <.svg variant="user-icon" class="w-5 h-5" /> Profile
                    </.link>
                    <.link
                      navigate={~p"/users/settings"}
                      class="flex items-center gap-2 px-4 py-2 text-white hover:bg-slate-600 transition-colors"
                    >
                      <.svg variant="gear" class="w-5 h-5" /> Settings
                    </.link>
                    <.link
                      navigate={~p"/studio"}
                      class="flex items-center gap-2 px-4 py-2 text-white hover:bg-slate-600 transition-colors"
                    >
                      <.svg variant="camera" class="w-5 h-5" /> Studio
                    </.link>
                    <.link
                      href={~p"/users/log-out"}
                      method="delete"
                      class="flex items-center gap-2 px-4 py-2 text-white hover:bg-slate-600 transition-colors"
                    >
                      <.svg variant="exit" class="w-5 h-5" /> Log Out
                    </.link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <.link
            navigate={~p"/auth"}
            class="hover:bg-blue-400 bg-transparent border-2 border-blue-500/60 text-white px-4 py-2 rounded-full transition-colors duration-300 ease-in-out"
          >
            Sign In / Register
          </.link>
        <% end %>
      </div>
    </header>

    <main class="pt-24 bg-[#0e0e10]">
      <div class="">{@inner_content}</div>
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

  def auth(assigns) do
    ~H"""
    <main class>{@inner_content}</main>
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
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
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
      <div class="absolute w-1/3 h-full rounded-full border border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />
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
