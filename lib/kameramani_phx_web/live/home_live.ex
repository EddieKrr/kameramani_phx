defmodule KameramaniPhxWeb.HomeLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.SidebarComponents

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_scope}

  @initial_state %{"ch_message" => ""}

  # --- PUBSUB HELPERS ---
  defp subscribe() do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "messages")
  end

  defp broadcast(value) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "messages", value)
  end

  # --- LIFECYCLE ---
  def mount(%{"stream_id" => stream_id}, _session, socket) do
    if connected?(socket), do: subscribe()

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

  # --- EVENT HANDLERS (Grouped) ---
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

      broadcast({:new_message, new_message})
      {:noreply, assign(socket, form: to_form(@initial_state, as: :chat))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate", %{"chat" => %{"ch_message" => message}}, socket) do
    form = to_form(%{"ch_message" => message}, as: :chat)
    {:noreply, assign(socket, form: form)}
  end

  # --- INFO HANDLERS ---
  def handle_info({:new_message, new_message}, socket) do
    {:noreply, stream_insert(socket, :messages, new_message)}
  end

  # --- RENDER ---
  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row h-screen w-full bg-[#060606] text-gray-100 overflow-hidden font-sans pt-16">

      <aside class="hidden lg:flex w-64 bg-[#0e0e10] border-r border-white/5 flex flex-col shrink-0">
        <div class="p-4 flex items-center gap-3">
          <div class="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center shrink-0 shadow-lg shadow-indigo-500/20">
            <.icon name="hero-bolt-solid" class="h-5 w-5 text-white" />
          </div>
          <span class="font-black text-lg tracking-tighter uppercase italic text-indigo-500">Kameramani</span>
        </div>

        <div class="flex-1 overflow-y-auto px-2 space-y-4 py-4 custom-scrollbar">
          <div class="px-2 text-[10px] font-bold text-gray-500 uppercase tracking-widest">Followed Channels</div>
          <div class="space-y-2">
            <.sidebar_item name="Jleel" game="Sims 4" viewer_count="5.2K" active={true} src="https://ui-avatars.com/api/?background=random"/>
            <.sidebar_item name="Slwan" game="Snowboard" viewer_count="3.1K" active={false} src="https://ui-avatars.com/api/?background=random"/>
          </div>
        </div>
      </aside>

      <main class="flex-1 flex flex-col min-w-0 bg-black overflow-y-auto custom-scrollbar">
        <div class="w-full aspect-video bg-[#000] relative sticky top-0 z-10 lg:relative shadow-2xl">
          <div class="absolute inset-0 flex items-center justify-center bg-[#0e0e10]">
            <div class="text-center">
               <div class="relative inline-block">
                  <div class="absolute inset-0 bg-indigo-500 blur-2xl opacity-20 animate-pulse"></div>
                  <.icon name="hero-video-camera-slash" class="h-12 w-12 md:h-20 md:w-20 text-gray-800 relative" />
               </div>
               <p class="mt-4 text-xs md:text-sm text-gray-500 font-medium tracking-tight">
                Waiting for signal from <span class="text-indigo-400 font-bold">@<%= @stream_id %></span>
               </p>
            </div>
          </div>
          <div class="absolute top-4 left-4 flex items-center gap-2">
            <span class="bg-red-600 text-[9px] md:text-[10px] font-black px-2 py-0.5 rounded shadow-lg animate-pulse">LIVE</span>
          </div>
        </div>

        <div class="p-4 md:p-6 bg-[#0e0e10] border-b border-white/5">
          <div class="flex items-center justify-between gap-4">
            <div class="flex items-center gap-3 md:gap-4">
              <div class="w-10 h-10 md:w-14 md:h-14 rounded-full p-0.5 bg-gradient-to-tr from-indigo-500 to-purple-500">
                 <div class="w-full h-full bg-[#0e0e10] rounded-full flex items-center justify-center text-sm md:text-xl font-black italic">
                   <%= String.at(@stream_id, 0) |> String.upcase() %>
                 </div>
              </div>
              <div class="min-w-0">
                <h1 class="text-sm md:text-xl font-bold truncate uppercase tracking-widest text-white"><%= @stream_id %></h1>
                <div class="flex items-center gap-2 text-[10px] md:text-xs font-medium text-gray-400 mt-0.5">
                  <span class="text-indigo-400 font-bold">#Elixir</span>
                  <span class="w-1 h-1 bg-gray-600 rounded-full"></span>
                  <span>English</span>
                </div>
              </div>
            </div>
            <button class="bg-indigo-600 hover:bg-indigo-500 px-4 md:px-6 py-1.5 md:py-2 rounded-lg font-bold text-[10px] md:text-sm transition-all shrink-0 text-white">
              Follow
            </button>
          </div>
        </div>

        <div class="flex lg:hidden flex-col h-[500px] bg-[#0e0e10]">
          <div class="p-3 border-b border-white/5 flex justify-between items-center">
            <span class="text-[10px] font-black uppercase tracking-widest text-gray-400">Live Chat</span>
          </div>
          <div class="flex-1 overflow-y-auto p-4 space-y-2 custom-scrollbar" id="chat-messages-mobile" phx-update="stream">
             <div :for={{dom_id, msg} <- @streams.messages} id={dom_id <> "-mob"} class="text-[13px] leading-relaxed">
                <span class="font-bold" style={"color: #{msg.color}"}><%= msg.name %>:</span>
                <span class="text-gray-300 ml-1"><%= msg.text %></span>
             </div>
          </div>
          <div class="p-4 border-t border-white/5">
             <.form for={@form} phx-submit="send_message" class="flex gap-2">
                <.input field={@form[:ch_message]} placeholder="Send a message..." autocomplete="off" class="flex-1 bg-black/40 text-sm border-white/10" />
                <button type="submit" class="bg-indigo-600 p-2 rounded-lg text-white"><.icon name="hero-paper-airplane-solid" class="h-5 w-5"/></button>
             </.form>
          </div>
        </div>
      </main>

      <aside class="hidden lg:flex w-80 bg-[#0e0e10] border-l border-white/5 flex flex-col shrink-0 shadow-[-10px_0_30px_rgba(0,0,0,0.5)]">
        <div class="h-14 flex items-center justify-between px-4 border-b border-white/5 bg-[#0e0e10]/50 backdrop-blur-md">
          <div class="flex items-center gap-2">
            <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
            <span class="text-[11px] font-black uppercase tracking-[0.2em] text-gray-300">Live Chat</span>
          </div>
        </div>

        <div class="flex-1 overflow-y-auto p-2 space-y-0.5 custom-scrollbar" id="chat-messages" phx-update="stream">
          <div :for={{dom_id, msg} <- @streams.messages} id={dom_id} class="group">
            <div class="px-2 py-1.5 rounded-md hover:bg-white/[0.04] transition-all duration-200 border border-transparent hover:border-white/5">
              <div class="flex items-start gap-2">
                <span class="mt-1 font-mono text-[9px] text-gray-600 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"><%= msg.dt %></span>
                <div class="flex-1 leading-tight">
                  <span class="font-black text-[13px] tracking-tight" style={"color: #{msg.color}"}><%= msg.name %></span>
                  <span class="text-gray-200 text-[13px] ml-2 break-words font-medium"><%= msg.text %></span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="p-4 bg-[#0e0e10] border-t border-white/5">
          <.form for={@form} phx-change="validate" phx-submit="send_message" class="space-y-3">
            <div class="relative">
              <.input field={@form[:ch_message]} placeholder="Send a message..." autocomplete="off"
                class="w-full bg-black/40 border-white/5 text-sm rounded-xl py-3 px-4 focus:ring-1 focus:ring-indigo-500/50 transition-all" />
            </div>
            <div class="flex justify-end">
              <button type="submit" class="bg-indigo-600 hover:bg-indigo-500 disabled:bg-gray-800 disabled:text-gray-600 px-6 py-2 rounded-lg text-[11px] font-black uppercase tracking-widest text-white transition-all active:scale-95"
                disabled={String.trim(@form[:ch_message].value || "") == ""}>
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
