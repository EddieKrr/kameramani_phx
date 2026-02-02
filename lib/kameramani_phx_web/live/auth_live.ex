defmodule KameramaniPhxWeb.AuthLive do
  use KameramaniPhxWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container group mx-auto my-18 relative w-[768px] max-w-full min-h-[480px] bg-indigo-200 rounded-[30px] shadow-2xl overflow-hidden">
    <div class="toggle-box absolute top-0 left-1/2 w-full h-full z-10 overflow-hidden transition-all duration-[600ms] ease-in-out group-[.active]:-translate-x-full rounded-l-[150px] group-[.active]:rounded-l-none group-[.active]:rounded-r-[150px]">
        <div class="absolute h-full w-[300%] left-[-100%] bg-gradient-to-r from-sky-500 via-indigo-950 to-slate-950 text-white transition-transform duration-[600ms] ease-in-out group-[.active]:translate-x-1/2">
        </div>
        <div class="toggle-panel login absolute w-1/2 h-full flex flex-col justify-center items-center px-8 text-center top-0 transition-all duration-600 ease-in-out left-0 group-[.active]:-left-1/2 delay-300">
            <h1 class="text-xl font-bold">Not Part of the Family?</h1>
            <p class="mb-5">Go ahead and register</p>
            <button phx-click={JS.add_class("active", to: ".container")} class="log-btn w-40 h-11 bg-transparent rounded-full border-2 border-white shadow-none">Sign Up</button>
        </div>
        <div class="toggle-panel register absolute w-1/2 h-full flex flex-col justify-center items-center px-8 text-center top-0 transition-all duration-600 ease-in-out -right-1/2 group-[.active]:right-0 group-[.active]:delay-300">
            <h1 class="text-xl font-bold">You're better than them?</h1>
            <p>Go ahead and login</p>
            <button phx-click={JS.remove_class("active", to: ".container")} class="reg-btn w-40 h-11 bg-transparent rounded-full border-2 border-white shadow-none">Sign Up</button>
        </div>
      </div>
    </div>
    """
  end
end
