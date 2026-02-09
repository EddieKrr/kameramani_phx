defmodule RegComponents do
  use KameramaniPhxWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type username age email password)

  def mesage(assigns) do
    ~H"""
      <input type={@type} id={@field.id} name={@field.name} value={@field.value} {@rest} class="border-2 border-indigo-700 rounded-3xl focus:outline-none text-center"/>
      <div :for={msg <- @field.errors} class="text-red-500"><%= elem(msg, 0) %></div>
    """
  end
end

defmodule LogComponents do
  use KameramaniPhxWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type username password name)

  def log(assigns) do
    ~H"""
    <input type={@type} id={@field.id} name={@field.name} value={@field.value} {@rest} class="rounded-full border-2 border-sky-500 focus:outline-none text-slate-800 text-center"/>
    <div :for={msg <- @field.errors} class="text-red-500"><%= elem(msg, 0) %></div>
    """
  end
end
