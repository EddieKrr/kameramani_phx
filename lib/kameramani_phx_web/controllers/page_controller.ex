defmodule KameramaniPhxWeb.PageController do
  use KameramaniPhxWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
