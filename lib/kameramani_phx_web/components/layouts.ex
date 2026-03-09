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

  attr :inner_content, :any, default: nil
  slot :inner_block
  attr :page_bg_class, :string, default: "bg-img bg-cover bg-fixed bg-center min-h-screen"
  attr :layout_type, :atom, default: :default, values: [:admin, :default]

  def app(assigns) do
    current_user =
      case assigns.current_user do
        nil -> nil
        %{} = map -> Map.get(map, :user, map)
        other -> other
      end

    socket = Map.get(assigns, :socket)
    is_chat_page = socket && socket.view == KameramaniPhxWeb.ChatLive

    assigns =
      assigns
      |> assign(:current_user_obj, current_user)
      |> assign(:is_chat_page, is_chat_page)
      |> assign(:live_socket, socket)

    ~H"""
    <div class={@page_bg_class}>
      <%= case @layout_type do %>
        <% :admin -> %>
          <header class="bg-white flex justify-between items-center p-4 text-black mb-2">
            <div class="flex flex-col">
              <span class="text-2xl font-title font-bold tracking-tighter uppercase italic text-blue-400">
                kameramani
              </span>
              <sub class="self-end">ADMIN</sub>
            </div>
            <div>
              <.link navigate={~p"/admin/overview"} ><span class="bg-blue-200 p-3 rounded-full text-blue-900 font-bold px-4">Overview</span></.link>
              <span class="p-3 bg-blue-200 rounded-full px-4">Live Streaming</span>
              <span class="bg-blue-200 p-3 rounded-full  px-4">Analytics</span>
            </div>
            <div>
              <div class="flex items-center gap-6">
                <div class="flex items-center gap-3">
                  <%= if @live_socket do %>
                    <%= Phoenix.Component.live_render(@live_socket, KameramaniPhxWeb.NotificationsLive,
                      id: "admin-navbar-notifications",
                      session: %{"current_user_id" => @current_user_obj.id}
                    ) %>
                  <% end %>
                  <span class="text-black">
                    Welcome,
                    <span class="font-semibold text-blue-400 capitalize">
                      {@current_user_obj.username}
                    </span>
                  </span>
                  <div class="relative group cursor-pointer">
                    <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                      {String.first(@current_user_obj.username || "U")
                      |> String.upcase()}
                    </div>

                    <div class="absolute right-0 top-full mt-2 w-48 glass-pane opacity-0 invisible group-hover:opacity-100 group-hover:visible group-hover:rounded-3xl transition-all duration-200 z-50">
                      <div class="py-2">
                        <.link
                          navigate={~p"/users/profile/#{@current_user_obj.username}"}
                          class="menu-item"
                        >
                          <.svg variant="user-icon" class="w-5 h-5" /> Profile
                        </.link>
                        <.link
                          navigate={~p"/users/settings"}
                          class="menu-item"
                        >
                          <.svg variant="gear" class="w-5 h-5" /> Settings
                        </.link>
                        <.link
                          navigate={~p"/studio"}
                          class="menu-item"
                        >
                          <.svg variant="camera" class="w-5 h-5" /> Studio
                        </.link>
                        <.link
                          navigate={~p"/directory"}
                          class="menu-item"
                        >
                          <.svg variant="folder" class="h-5 w-5" /> Categories
                        </.link>
                        <.link
                          href={~p"/users/log-out"}
                          method="delete"
                          class="menu-item"
                        >
                          <.svg variant="exit" class="w-5 h-5" /> Log Out
                        </.link>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </header>
        <% :default -> %>
          <header
            class={"navbar sticky top-0 left-0 right-0 z-50 flex items-center justify-between #{if @is_chat_page, do: "mx-auto w-full max-w-[1440px]", else: "px-4 sm:px-6 lg:px-8"}"}
            style="width: 100%;"
          >
            <div class={"flex items-center gap-4 justify-between glass-pane px-4 w-full sm:px-6 py-3 mx-auto #{if @is_chat_page, do: "rounded-xl w-full"}"}>
              <div class="flex">
                <.link
                  href="/"
                  class="flex items-center gap-2 text-blue-400 hover:text-blue-300 transition-colors"
                >
                  <span class="text-2xl font-title font-bold tracking-tighter uppercase italic">
                    Kameramani
                  </span>
                </.link>
              </div>

              <%= if @current_user_obj do %>
                <div class="flex items-center gap-6">
                  <.live_component
                    module={KameramaniPhxWeb.NavbarSearchComponent}
                    id={"navbar-search-#{if @inner_content, do: "root", else: "inner"}"}
                    current_user={@current_user}
                  />
                  <div class="flex items-center gap-3">
                    <%= if @live_socket do %>
                      <%= Phoenix.Component.live_render(@live_socket, KameramaniPhxWeb.NotificationsLive,
                        id: "navbar-notifications",
                        session: %{"current_user_id" => @current_user_obj.id}
                      ) %>
                    <% end %>
                    <span class="text-white">
                      Welcome,
                      <span class="font-semibold text-blue-400 capitalize">
                        {@current_user_obj.username}
                      </span>
                    </span>
                    <div class="relative group cursor-pointer">
                      <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                        {String.first(@current_user_obj.username || "U")
                        |> String.upcase()}
                      </div>

                      <div class="absolute right-0 top-full mt-2 w-48 glass opacity-0 invisible group-hover:opacity-100 group-hover:visible group-hover:rounded-3xl transition-all duration-200 z-50">
                        <div class="py-2">
                          <.link
                            navigate={~p"/users/profile/#{@current_user_obj.username}"}
                            class="menu-item"
                          >
                            <.svg variant="user-icon" class="w-5 h-5" /> Profile
                          </.link>
                          <.link
                            navigate={~p"/users/settings"}
                            class="menu-item"
                          >
                            <.svg variant="gear" class="w-5 h-5" /> Settings
                          </.link>
                          <.link
                            navigate={~p"/studio"}
                            class="menu-item"
                          >
                            <.svg variant="camera" class="w-5 h-5" /> Studio
                          </.link>
                          <.link
                            navigate={~p"/directory"}
                            class="menu-item"
                          >
                            <.svg variant="folder" class="h-5 w-5" /> Categories
                          </.link>
                          <.link
                            href={~p"/users/log-out"}
                            method="delete"
                            class="menu-item"
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
      <% end %>
      <main class="text-white bg-transparent">
        <div class="">
          <%= if @inner_content do %>
            {@inner_content}
          <% else %>
            {render_slot(@inner_block)}
          <% end %>
        </div>
      </main>
      <.flash_group flash={@flash} />
    </div>
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
  attr :inner_content, :any, default: nil
  attr :page_bg_class, :string, default: "bg-img bg-cover bg-fixed bg-center min-h-screen"
  slot :inner_block

  def auth(assigns) do
    ~H"""
    <div class={@page_bg_class}>
    <div class="min-h-screen glass-pane text-white flex flex-col items-center justify-center">
      <%= if @inner_content do %>
        {@inner_content}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Renders a group of flash messages for different kinds.
  """
  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div class="fixed top-2 right-0 z-50 flex flex-col gap-3 pointer-events-none">
      <.flash
        kind={:info}
        title="Success"
        flash={@flash}
      />
      <.flash
        kind={:error}
        title="Error"
        flash={@flash}
      />
      <.flash
        id="client-error"
        kind={:error}
        title="Connection lost"
        phx-disconnected={JS.show(to: "#client-error")}
        phx-connected={JS.hide(to: "#client-error")}
        class="hidden opacity-0 transition-opacity duration-1000 delay-1000 phx-loading:opacity-100"
      >
        Trying to reconnect...
        <.icon name="hero-arrow-path" class="ml-1 size-3 animate-spin inline-block" />
      </.flash>
      <.flash
        id="server-error"
        kind={:error}
        title="Server issue"
        phx-disconnected={JS.show(to: "#server-error")}
        phx-connected={JS.hide(to: "#server-error")}
        class="hidden opacity-0 transition-opacity duration-1000 delay-1000 phx-loading:opacity-100"
      >
        We're working on getting things back on track.
        <.icon name="hero-arrow-path" class="ml-1 size-3 animate-spin inline-block" />
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
        <.svg variant="desktop" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.svg variant="sun" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.svg variant="moon" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
