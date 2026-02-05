defmodule KameramaniPhxWeb.HomeLive do
  use KameramaniPhxWeb, :live_view


    @initial_state%{
      "ch_message" => ""
    }


  def mount(%{"stream_id" => stream_id}, _session, socket) do
    name_list= ["BIG C", "you canna", "bis", "mafrr"]
    username = Enum.random(name_list)
    user_color = RandomColour.generate()
    form=to_form(@initial_state, as: :chat)
    {:ok, assign(socket, form: form, messages: [], username: username, user_color: user_color,  stream_id: stream_id)}
  end

  def handle_event("send_message",%{"chat" => %{ "ch_message" => message}}, socket) do
    new_message = %{name: socket.assigns.username,  text: message, dt: Calendar.strftime(Time.utc_now(), "%I:%M:%S %p"), color: socket.assigns.user_color}
    IO.inspect(message, label: "IT ARRIVED")
    empty_form=to_form(@initial_state, as: :chat)
    {:noreply, assign(socket, messages: socket.assigns.messages++ [new_message],
    form: empty_form)}
  end

  def handle_event("validate", params, socket) do
    blank_form=to_form(params, as: :chat)
    {:noreply, assign(socket, form: blank_form)}
  end

  def render(assigns) do
    ~H"""
    <div class = "flex flex-col h-screen overflow-hidden bg-gray-800">
      <div class = "flex flex-row h-16 w-screen flex-none justify-between border-b border-gray-600 items-center static">
        <div><.icon name="hero-cube-transparent-mini"/></div>
        <div class="border-2 border-blue-500 w-1/3 rounded-lg justify-center items-center relative">
          <div class="">

            <.icon name="hero-magnifying-glass-solid" class="absolute inset-y-0 right-0"/>
          </div>
        </div>
        <div></div>
      </div>
      <div class = "flex flex-row h-screen w-screen overflow-hidden">
        <div class = "flex flex-col w-64 h-screen overflow-y-auto bg-gray-800 p-3 gap-2 ">
           <.sidebar_item name ={"Jleel"} game={"Sims 4"} viewer_count={5000} src="https://ui-avatars.com/api/?background=random"/>
           <.sidebar_item name ={"Slwan"} game={"Snowboard Sim"} viewer_count={3000} src="https://ui-avatars.com/api/?background=random"/>
           <.sidebar_item name ={"Jmrqui"} game={"Virtual Insanity"} viewer_count={2013} src="https://ui-avatars.com/api/?background=random"/>
        </div>
        <div class = "flex flex-grow items-center justify-center">
          <div class ="flex h-full bg-black w-full max-w-6xl rounded-xl shadow-2xl overflow-hidden items-center justify-center">
            <text class ="text-gray-500">Waiting for Signal....</text>
          </div>
        </div>
        <div class = "flex flex-col w-80 min-h-0 overflow-hidden bg-gray-800">
          <div class="flex flex-1 flex-col overflow-y-auto break-words ">
            <div :for={msg <-@messages}>
              <.chat_message dt={msg.dt} name={msg.name} text={msg.text} color={msg.color}/>
            </div>
          </div>
          <div class="h-24 flex flex-row items-center px-4">
          <.form
            for={@form}
            phx-change="validate"
            phx-submit="send_message"
            class="flex w-full items-center gap-3 "
            >
            <.input
                field={@form[:ch_message]}
                placeholder="Enter Message Here"
                class="w-full bg-gray-900 text-white rounded-full px-4 border-none focus:outline-none h-10 justify-end"
              />
              <button type="submit" class="pb-3 "><.icon name="hero-paper-airplane-solid" class="h-5 w-5 text-blue-500" /></button>
          </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

end
