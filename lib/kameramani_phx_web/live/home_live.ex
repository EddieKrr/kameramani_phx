defmodule KameramaniPhxWeb.HomeLive do
  use KameramaniPhxWeb, :live_view


    @initial_state%{
      "ch_message" => ""
    }


  def mount(_params, _session, socket) do
    name_list= ["BIG C", "you canna", "bis", "mafrr"]
    username = Enum.random(name_list)
    user_color = RandomColour.generate()
    form=to_form(@initial_state, as: :chat)
    {:ok, assign(socket, form: form, messages: [], username: username, user_color: user_color)}
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
      <div class = "h-16 w-screen flex-none"></div>
      <div class = "flex flex-row h-screen w-screen overflow-hidden">
        <div class = "flex flex-col w-64 h-screen overflow-y-auto bg-gray-800 p-3 gap-2 ">
           <.sidebar_item name ={"Jleel"} game={"Sims 4"} viewer_count={5000} src="https://ui-avatars.com/api/?background=random"/>
           <.sidebar_item name ={"Slwan"} game={"Snowboard Sim"} viewer_count={3000} src="https://ui-avatars.com/api/?background=random"/>
           <.sidebar_item name ={"Jmrqui"} game={"Virtual Insanity"} viewer_count={2013} src="https://ui-avatars.com/api/?background=random"/>
        </div>
        <div class = "flex flex-grow flex-col h-screen bg-gray-900"></div>
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
            class="flex w-full items-center gap-3"
            >
            <.input
                field={@form[:ch_message]}
                placeholder="Enter Message Here"
                class="flex-1 bg-gray-900 text-white rounded-full px-4 border-none focus:outline-none h-10"
              />
              <button type="submit" class="bg-green-700 text-white hover: bg-green-500 rounded-full flex-1">Send</button>
          </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

end
