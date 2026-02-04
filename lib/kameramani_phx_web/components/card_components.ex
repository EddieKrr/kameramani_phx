defmodule KameramaniPhxWeb.CardComponents do
  use KameramaniPhxWeb, :html

  def card(assigns) do
    ~H"""
    <article>
      <div class="thmb relative aspect-video w-full bg-gradient-to-tl from-black to-slate-700">
        <div class="lv-ind absolute top-1 left-1 bg-red-500 rounded-full px-1 text-xs">LIVE</div>
        <div class="v-cnt absolute bottom-1 right-1 bg-black/60 rounded-full text-xs px-1">3000</div>
      </div>
      <div class="m-dt flex flex-row gap-3">
        <img class="avt h-10 w-10 rounded-full" src="https://ui-avatars.com/api/?background=random">
        <div class="txtwrp flex flex-col">
          <div class="ttle font-bold text-white truncate gap-2">Elden Ring</div>
          <div class="txt text-gray-400 text-sm">XQC</div>
          <div class="ctgry text-gray-400 text-sm">RPG</div>
          <div class="tag bg-gray-700 text-xs text-gray-300 rounded-full px-2 w-fit">Just Chatting</div>
        </div>
      </div>
    </article>
    """
  end
end
