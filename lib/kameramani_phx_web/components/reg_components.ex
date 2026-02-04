defmodule RegComponents do
  use KameramaniPhxWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type username age email password)

  def mesage(assigns) do
    ~H"""
      <input type="text" id={@field.id} name={@field.name} {@rest} class="border-2 border-indigo-700 rounded-3xl focus:outline-none justify-center items-center"/>
      <div :for={msg <- @field.errors} class="text-red-500"><%=msg%></div>
    """
  end
end

defmodule LogComponents do
  use KameramaniPhxWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type username password)

  def log(assigns) do
    ~H"""
    <input type="text" id={@field.id} username={@field.name} {@rest} class="rounded-full border-2 border-sky-500 focus:outline-none text-slate-800"/>
    <div :for={msg <- @field.errors} class="text-red-500"><%=msg%></div>
    """
  end
end
