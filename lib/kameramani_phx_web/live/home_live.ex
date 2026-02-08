defmodule KameramaniPhxWeb.HomeLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.NavComponents
  import KameramaniPhxWeb.SidebarComponents

  defp subscribe() do
    Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "messages")
  end

  defp broadcast(value) do
    Phoenix.PubSub.broadcast(KameramaniPhx.PubSub, "messages", value)
  end

    @initial_state%{
      "ch_message" => ""
    }


  def mount(%{"stream_id" => stream_id}, _session, socket) do
    if connected?(socket) do
      subscribe()
    end
    name_list= ["BIG C", "you canna", "bis", "mafrr"]
    username = Enum.random(name_list)
    user_color = RandomColour.generate()
    form=to_form(@initial_state, as: :chat)
    {:ok, assign(socket, form: form, messages: [], username: username, user_color: user_color,  stream_id: stream_id, current_user: nil, show_sidebar: false, show_chat: false)}
  end

  def handle_event("send_message",%{"chat" => %{ "ch_message" => message}}, socket) do
    new_message = %{name: socket.assigns.username,  text: message, dt: Calendar.strftime(Time.utc_now(), "%I:%M:%S %p"), color: socket.assigns.user_color}
    nu_msg = socket.assigns.messages++ [new_message]
    broadcast({:messages, nu_msg})

    IO.inspect(message, label: "IT ARRIVED")
    empty_form=to_form(@initial_state, as: :chat)
    {:noreply, assign(socket, form: empty_form, messages: nu_msg)}
  end

  def handle_event("validate", params, socket) do
    updated_form=to_form(params, as: :chat)
    {:noreply, assign(socket, form: updated_form)}
  end

  def handle_info({:messages, nu_msg}, socket) do

    {:noreply, assign(socket, messages: nu_msg)}
  end

  def render(assigns) do
    ~H"""
    <div class = "flex flex-col h-screen overflow-hidden bg-gray-800">
      <.navbar current_user={@current_user} layout={:fixed}/>
      <div class = "grid sm:grid-cols-1 lg:grid-cols-[256px_1fr_340px] w-full h-[calc(100vh-4rem)]">
        <div class = "p-2 bg-gray-800 border-r border-gray-700 overflow-y-auto hidden lg:block">
           <.sidebar_item name ={"Jleel"} game={"Sims 4"} viewer_count={5000} src="https://ui-avatars.com/api/?background=random"/>
           <.sidebar_item name ={"Slwan"} game={"Snowboard Sim"} viewer_count={3000} src="https://ui-avatars.com/api/?background=random"/>
           <.sidebar_item name ={"Jmrqui"} game={"Virtual Insanity"} viewer_count={2013} src="https://ui-avatars.com/api/?background=random"/>
        </div>
        <div class = "relative flex items-center justify-center w-full h-full bg-black">
            <span class ="text-gray-500">Waiting for Signal....</span>
        </div>
        <div class = " hidden lg:flex flex-col min-h-0 overflow-hidden bg-gray-800 border-l border-gray-700">
          <div class="flex flex-1 flex-col overflow-y-auto break-words p-4 gap-2">
            <div :for={msg <-@messages}>
              <.chat_message dt={msg.dt} name={msg.name} text={msg.text} color={msg.color}/>
            </div>
          </div>

          <div class="h-24 flex flex-none items-center px-4 border-t border-gray-700">
          <.form
            for={@form}
            phx-change="validate"
            phx-submit="send_message"
            class="flex w-full items-center gap-3 "
            >
            <.input
                field={@form[:ch_message]}
                placeholder="Enter Message Here"
                class="w-full bg-gray-900 text-white rounded-full px-4 border-none focus:ring-1 focus:ring-blue-500 h-10"
              />
              <button type="submit" class="p-2 hover:bg-gray-700 rounded-full transition-colors"><.icon name="hero-paper-airplane-solid" class="h-5 w-5 text-blue-500" /></button>
          </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end
  defp sidebar_classes(show?) do
    base = "bg-gray-800 border-r border-gray-700 overflow-y-auto transition-all duration 300"
    desktop = "lg:block lg:static lg:w-auto lg:h-auto"
    mobile = if show?, do: "absolute top-0 left-0 h-full w-64 z-40 block shadow-2xl", else: "hidden"

    "#{base} #{desktop} #{mobile}"
  end

  defp chat_classes(show?) do
    base = "flex flex-col overflow-hidden bg-gray-800 border-l border-gray-700 transition-all duration"
    desktop = "lg:flex lg:static lg:w-auto lg:h-auto"
    mobile = if show?, do: "absolute top-0 right-0 h-full w-80 z-40 flex shadow-2xl", else: "hidden"

    "#{base} #{desktop} #{mobile}"
  end
end
