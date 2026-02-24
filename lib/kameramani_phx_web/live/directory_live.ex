defmodule KameramaniPhxWeb.DirectoryLive do
alias KameramaniPhxWeb.CardComponents
  use KameramaniPhxWeb, :live_view

  import CardComponents

  def list_categories do
    [
      %{name: "Just Chatting", slug: "jt_cht", viewers: 7000},
      %{name: "Racing", slug: "rcng", viewers: 7000},
      %{name: "Gambling", slug: "lt_it_rde", viewers: 7000},
      %{name: "Strategy", slug: "strt", viewers: 7000}
    ]
  end

  def mount(_params, _session, socket) do
    mock_ls =  list_categories()
    {:ok, assign(socket, mock_ls: mock_ls)}
  end
end
