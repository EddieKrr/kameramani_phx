# defmodule KameramaniPhxWeb.DirectoryLive do
# alias KameramaniPhxWeb.CardComponents
#   use KameramaniPhxWeb, :live_view

#   import CardComponents

#   defp list_categories(_params, _session, socket) do
#     mock_ls = [
#       %{name: "Just Chatting", slug: "jt_cht", viewers: 7000},
#       %{name: "Racing", slug: "rcng", viewers: 7000},
#       %{name: "Gambling", slug: "lt_it_rde", viewers: 7000},
#       %{name: "Strategy", slug: "strt", viewers: 7000}
#     ]
#   end

#   def mount(_params, _session, socket) do
#     # categories = list_categories()
#     active_categoy= nil
#     {:ok, assign(socket, categories)}
#   end

#   def render(assigns) do
#     ~H"""
#       <div class="">
#         <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
#           <.category_card
#           :for= {category_card <- @mock_ls}
#           name={category_card.name}
#           slug={category_card.slug}
#           viewers={category_card.viewers}
#         />
#         </div>
#       </div>
#     """
#   end

# end
