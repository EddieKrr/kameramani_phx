defmodule RegComponents do
  use KameramaniPhxWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type username age email password)

  def mesage(assigns) do
    ~H"""
      <input type="text" id={@field.id} name={@field.name} {@rest} class="border-2 border-sky-950 rounded-lg focus:outline-none"/>
      <div :for={msg <- @field.errors}><%=msg%></div>
    """
  end
end
