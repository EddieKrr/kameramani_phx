defmodule KameramaniPhxWeb.HomeLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_scope}

  @initial_state %{"ch_message" => ""}

  def mount(%{"stream_id" => stream_id}, _session, socket) do
    username = Enum.random(["BIG C", "Canna", "Bis", "Mafrr"])
    user_color = "#" <> (for _ <- 1..3, into: "", do: Integer.to_string(Enum.random(100..255), 16))

    {:ok,
     socket
     |> assign(
       form: to_form(@initial_state, as: :chat),
       username: username,
       user_color: user_color,
       stream_id: stream_id,
       game: "Sims 4"
     )

     |> stream(:messages, [])}
  end

  def handle_event("send_message", %{"chat" => %{"ch_message" => message}}, socket) do
    message = String.trim(message)

    if message != "" do
      new_message = %{
        id: System.unique_integer([:positive]),
        name: socket.assigns.username,
        text: message,
        dt: DateTime.utc_now() |> Calendar.strftime("%H:%M"),
        color: socket.assigns.user_color
      }

      # Insert message into stream and reset form
      socket =
        socket
        |> stream_insert(:messages, new_message)
        |> assign(form: to_form(@initial_state, as: :chat))

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate", %{"chat" => %{"ch_message" => message}}, socket) do
    form = to_form(%{"ch_message" => message}, as: :chat)
    {:noreply, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen w-full bg-[#060606] text-gray-100 overflow-hidden font-sans">
      <aside class="w-[70px] xl:w-64 bg-[#0e0e10] border-r border-white/5 flex flex-col transition-all duration-300">
        <div class="p-4 flex items-center gap-3">
          <div class="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center shrink-0 shadow-lg shadow-indigo-500/20">
            <.icon name="hero-bolt-solid" class="h-5 w-5 text-white" />
          </div>
          <span class="font-black text-lg tracking-tighter hidden xl:block uppercase">Kameramani</span>
        </div>

        <div class="flex-1 overflow-y-auto px-2 space-y-4 py-4">
          <div class="hidden xl:block px-2 text-[10px] font-bold text-gray-500 uppercase tracking-widest">Followed</div>
          <div class="space-y-2">
            <.sidebar_item name="Jleel" game="Sims 4" viewer_count={5200} src="https://ui-avatars.com/api/?background=random"/>
            <.sidebar_item name="Slwan" game="Snowboard" viewer_count={3000} src="https://ui-avatars.com/api/?background=random"/>
          </div>
        </div>
      </aside>

      <main class="flex-1 flex flex-col min-w-0 bg-black overflow-y-auto">
        <div class="w-full aspect-video bg-[#000] relative group ring-1 ring-white/5 shadow-2xl">
          <div class="absolute inset-0 flex items-center justify-center bg-[#0e0e10]">
            <div class="text-center group-hover:scale-105 transition-transform duration-500">
               <div class="relative inline-block">
                  <div class="absolute inset-0 bg-indigo-500 blur-2xl opacity-20 animate-pulse"></div>
                  <.icon name="hero-video-camera-slash" class="h-20 w-20 text-gray-800 relative" />
               </div>
               <p class="mt-4 text-gray-500 font-medium tracking-tight">Waiting for signal from <span class="text-indigo-400 font-bold">@<%= @stream_id %></span></p>
            </div>
          </div>

          <div class="absolute top-6 left-6 flex items-center gap-2">
            <span class="bg-red-600 text-[10px] font-black px-2 py-0.5 rounded shadow-lg animate-pulse">LIVE</span>
            <span class="bg-black/60 backdrop-blur-md text-[10px] font-bold px-2 py-0.5 rounded border border-white/10">02:14:55</span>
          </div>
        </div>

        <div class="p-6 bg-[#0e0e10] border-t border-white/5">
          <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="flex items-center gap-4">
              <div class="w-14 h-14 rounded-full p-0.5 bg-gradient-to-tr from-indigo-500 to-purple-500">
                 <div class="w-full h-full bg-[#0e0e10] rounded-full flex items-center justify-center text-xl font-black">
                   <%= String.at(@stream_id, 0) %>
                 </div>
              </div>
              <div>
                <h1 class="text-xl font-bold tracking-tight"><%= @stream_id %> Stream Session</h1>
                <div class="flex items-center gap-3 text-xs font-medium text-gray-400 mt-1">
                  <span class="text-indigo-400">#</span>
                  <span class="w-1 h-1 bg-gray-600 rounded-full"></span>
                  <span>English</span>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button class="bg-indigo-600 hover:bg-indigo-500 px-6 py-2 rounded-lg font-bold text-sm transition-all active:scale-95 shadow-lg shadow-indigo-600/20">Follow</button>
              <button class="bg-white/5 hover:bg-white/10 p-2 rounded-lg transition-colors border border-white/10">
                <.icon name="hero-share-solid" class="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </main>

      <aside class="w-80 bg-[#0e0e10] border-l border-white/5 flex flex-col shadow-[-10px_0_30px_rgba(0,0,0,0.5)]">
        <div class="h-14 flex items-center justify-between px-4 border-b border-white/5 bg-[#18181b]/50">
          <span class="text-[11px] font-black uppercase tracking-[0.2em] text-gray-400">Stream Chat</span>
          <.icon name="hero-users-solid" class="h-4 w-4 text-gray-600" />
        </div>

        <div
          class="flex-1 overflow-y-auto p-2 space-y-0.5 custom-scrollbar"
          id="chat-messages"
          phx-update="stream"
        >
          <div :for={{dom_id, msg} <- @streams.messages} id={dom_id} class="group animate-in slide-in-from-bottom-2 duration-300">
            <div class="px-2 py-1.5 rounded hover:bg-white/[0.03] transition-colors">
              <div class="flex items-baseline flex-wrap text-[13px] leading-snug">
                <span class="text-[9px] font-mono text-gray-600 mr-2 tabular-nums group-hover:text-gray-400 transition-colors">
                  <%= msg.dt %>
                </span>
                <span class="font-bold hover:underline cursor-pointer tracking-tight" style={"color: #{msg.color}"}>
                  <%= msg.name %>
                </span>
                <span class="text-gray-300 ml-2 break-words">
                  <%= msg.text %>
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="p-4 bg-[#18181b]/80 border-t border-white/5 backdrop-blur-xl">
          <div class="mb-4 flex items-center justify-between">
             <div class="flex items-center gap-2 px-2 py-1 bg-white/5 rounded-md border border-white/5">
                <div class="w-3 h-3 rounded-sm shadow-sm" style={"background-color: #{@user_color}"}></div>
                <span class="text-[10px] font-black text-gray-400 uppercase tracking-tighter"><%= @username %></span>
             </div>
             <span class="text-[9px] font-bold text-indigo-400/60 uppercase">Commands Active</span>
          </div>

          <.form for={@form} phx-change="validate" phx-submit="send_message" class="space-y-3" id="chat-form">
            <div class="relative group">
              <.input
                field={@form[:ch_message]}
                placeholder="Type a message... (Press Enter to send)"
                autocomplete="off"
                class="w-full bg-[#0e0e10] border-2 border-transparent focus:border-indigo-500/40 focus:ring-0 text-white text-sm rounded-xl py-3 px-4 shadow-inner transition-all placeholder:text-gray-700"
                phx-hook="ChatInput"
              />
              <div class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-2">
                <button type="button" class="text-gray-600 hover:text-indigo-400 transition-colors">
                  <.icon name="hero-face-smile" class="h-5 w-5" />
                </button>
              </div>
            </div>

            <div class="flex items-center justify-between gap-3">
              <div class="flex gap-1">
                <button type="button" class="p-2 bg-white/5 hover:bg-white/10 rounded-lg text-gray-500 transition-colors">
                  <.icon name="hero-gift-solid" class="h-4 w-4" />
                </button>
                <button type="button" class="p-2 bg-white/5 hover:bg-white/10 rounded-lg text-gray-500 transition-colors">
                  <.icon name="hero-sparkles-solid" class="h-4 w-4" />
                </button>
              </div>
              <button
                type="submit"
                class="flex-1 md:flex-none bg-indigo-600 hover:bg-indigo-500 disabled:opacity-20 text-white text-xs font-black uppercase tracking-widest py-2.5 px-8 rounded-xl shadow-lg shadow-indigo-500/20 transition-all active:scale-95"
                disabled={String.trim(@form[:ch_message].value || "") == ""}
                phx-disable-with="Sending..."
              >
                Chat
              </button>
            </div>
          </.form>
        </div>
      </aside>
    </div>
    """
  end
end
