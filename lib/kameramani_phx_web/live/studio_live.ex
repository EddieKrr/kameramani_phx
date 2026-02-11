defmodule KameramaniPhxWeb.StudioLive do
  use KameramaniPhxWeb, :live_view

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_scope}
  import KameramaniPhxWeb.NavComponents
  import KameramaniPhxWeb.CoreComponents

  @default_stream_settings %{
    "title" => "My First Stream",
    "game" => "Just Chatting",
    "stream_key" => "live_sk_12345_SECRET"
  }

  def mount(_params, _session, socket) do
    form = to_form(@default_stream_settings, as: :stream_settings)

    {:ok,
     assign(socket,
       form: form,
       stream_key_visible: false,
       current_user: %{username: "Streamer", avatar: nil}
     )}
  end

  def handle_event("validate", %{"stream_settings" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: :stream_settings))}
  end

  def handle_event("save", %{"stream_settings" => params}, socket) do
    IO.inspect(params, label: "SAVING CONFIG")
    {:noreply, put_flash(socket, :info, "Stream info updated!")}
  end

  def handle_event("toggle_key", _, socket) do
    {:noreply, assign(socket, stream_key_visible: !socket.assigns.stream_key_visible)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
      socket
      |> assign(page_title: "Creator Studio")}
  end

  def render(assigns) do
    ~H"""
    <div class="h-[100%] bg-[#0e0e10] text-gray-100 font-sans pt-[64px]">
      <main class="max-w-7xl mx-auto p-6">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2 space-y-6">
            <div class="aspect-video bg-black rounded-xl relative border border-white/10 shadow-xl flex items-center justify-center group">
              <div class="text-center">
                <.icon name="hero-video-camera-slash" class="h-16 w-16 text-gray-700 mb-2 mx-auto" />
                <span class="text-gray-500 font-medium">Offline</span>
              </div>

              <div class="absolute top-4 left-4 bg-black/60 backdrop-blur px-2 py-1 rounded text-xs font-mono border border-white/10">
                PREVIEW
              </div>
            </div>

            <div class="bg-[#18181b] p-6 rounded-xl border border-white/5">
              <div class="flex items-center gap-2 mb-6 border-b border-white/5 pb-4">
                <.icon name="hero-pencil-square" class="h-5 w-5 text-indigo-500" />
                <h2 class="font-bold text-lg">Stream Info</h2>
              </div>

              <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
                <.input
                  field={@form[:title]}
                  label="Title"
                  placeholder="Stream Title"
                  class="bg-[#0e0e10] border-white/10 focus:border-indigo-500 text-white"
                />
                <div class="grid grid-cols-2 gap-4">
                  <.input
                    field={@form[:game]}
                    label="Category"
                    placeholder="e.g. Minecraft"
                    class="bg-[#0e0e10] border-white/10 focus:border-indigo-500 text-white"
                  />
                  <div class="fieldset mb-2">
                    <label class="label mb-1">Tags</label>
                    <div class="bg-[#0e0e10] border border-white/10 rounded-lg p-2.5 text-gray-500 text-sm">
                      English, Chill (Mock)
                    </div>
                  </div>
                </div>

                <div class="flex justify-end pt-2">
                  <.button
                    type="submit"
                    class="bg-indigo-600 hover:bg-indigo-500 text-white font-bold border-none rounded-lg p-2"
                  >
                    Update Info
                  </.button>
                </div>
              </.form>
            </div>
          </div>

          <div class="space-y-6">
            <div class="bg-[#18181b] p-6 rounded-xl border border-white/5">
              <h2 class="font-bold text-lg mb-4 text-white">Stream Key</h2>

              <div class="bg-black/50 p-3 rounded-lg border border-white/10 flex items-center gap-3">
                <div class="flex-1 font-mono text-sm text-gray-300 truncate tracking-widest">
                  <%= if @stream_key_visible do %>
                    {@form[:stream_key].value}
                  <% else %>
                    •••••••••••••••••••••••••
                  <% end %>
                </div>

                <button
                  phx-click="toggle_key"
                  class="text-gray-400 hover:text-white transition-colors"
                >
                  <%= if @stream_key_visible do %>
                    <.icon name="hero-eye-slash" class="h-5 w-5" />
                  <% else %>
                    <.icon name="hero-eye" class="h-5 w-5" />
                  <% end %>
                </button>
              </div>

              <p class="text-xs text-gray-500 mt-3 leading-relaxed">
                Paste this into OBS Settings > Stream. <br />
                <span class="text-red-400">Do not share this key with anyone.</span>
              </p>
            </div>

            <div class="bg-[#18181b] p-6 rounded-xl border border-white/5">
              <h2 class="font-bold text-lg mb-4 text-white">Actions</h2>

              <div class="grid grid-cols-2 gap-3">
                <button class="bg-red-900/30 text-red-400 border border-red-900/50 py-3 rounded-lg text-sm font-bold hover:bg-red-900/50 transition-colors">
                  Stop Stream
                </button>
                <button class="bg-gray-800 text-gray-300 border border-white/5 py-3 rounded-lg text-sm font-bold hover:bg-gray-700 transition-colors">
                  Raid Channel
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
