defmodule KameramaniPhxWeb.ChatComponents do
  use Phoenix.Component
  use Gettext, backend: KameramaniPhxWeb.Gettext

  attr :name, :string, required: true
  attr :color, :string, required: true
  attr :text, :string
  attr :dt, :any

  def chat_message(assigns) do
  #   dt = DateTime.utc_now() |> DateTime.to_time |> Time.truncate(:second)
  #   assigns = assign(assigns, dt: dt)

    ~H"""
    <div class="flex flex-row items-center gap-2">
      <div class="">{@dt}</div>
      <div style={"color:#{@color}"}>{@name}:</div>
      <div class="font-normal break-words">{@text}</div>
    </div>
    """
  end
end
