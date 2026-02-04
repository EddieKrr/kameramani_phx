defmodule KameramaniPhxWeb.AuthLive do
  use KameramaniPhxWeb, :live_view
  import RegComponents
  import LogComponents

  @empty_reg%{
    "name" => "",
    "username" => "",
    "email" => "",
    "age" => "",
    "password" => ""
  }

  @empty_log%{
    "username" => "",
    "password" => ""
  }

  def mount(_params, _session, socket) do
    reg_form=to_form(@empty_reg, as: :reg)
    log_form=to_form(@empty_log, as: :log)
    {:ok, assign(socket, reg_form: reg_form, log_form: log_form)}

  end

  def handle_event("validate_entry", %{"reg"=>form_msg}, socket) do
    errors = []

    errors =
    if form_msg["name"] == "" do
      Keyword.put(errors, :name, "Can't be blank")
    else
      errors
    end

    errors =
    if form_msg["username"] == "" do
      Keyword.put(errors, :username, "Can't be blank")
    else
      errors
    end

    errors =
    if form_msg["email"] == "" do
      Keyword.put(errors, :email, "Can't be blank")
    else
      errors
    end

    errors =
    if form_msg["age"] == "" do
      Keyword.put(errors, :age, "Can't be blank")
    else
      errors
    end

    errors =
    if form_msg["password"] == "" do
      Keyword.put(errors, :password, "Can't be blank")
    else
      errors
    end

    reg_form = to_form(form_msg, as: :reg, errors: errors)
    {:noreply, assign(socket, reg_form: reg_form)}
  end

  def handle_event("register", %{"reg"=>form_msg}, socket) do
    IO.inspect({"Form submitted!!!"}, form_msg)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-row container group mx-auto my-18 relative w-[768px] max-w-full min-h-[480px] bg-indigo-200 rounded-[30px] shadow-2xl overflow-hidden">
      <div class ="form-register flex w-1/2">
        <.form
          for={@reg_form}
          phx-change="validate_entry"
          phx-submit="register"
          class ="flex flex-col justify-right m-auto text-black gap-3"
        >
        <.mesage field={@reg_form[:name]} placeholder="Name"/>
        <.mesage field={@reg_form[:username]} placeholder="Username" />
        <.mesage field={@reg_form[:email]} placeholder="Email"/>
        <.mesage field={@reg_form[:age]} placeholder="Age" />
        <.mesage field={@reg_form[:password]} placeholder="Password"/>

        <button type="submit" class="rounded-full bg-indigo-700 p-2">Register</button>
        </.form>

      </div>
      <div class="form-login flex w-1/2 ">
        <.form
          for={@log_form}
          phx-change="validate_log"
          phx-submit="login"
          class="flex flex-col m-auto gap-2"
        >
        <.log field={@log_form[:name]} placeholder=" Username"/>
        <.log field={@log_form[:password]} placeholder=" Password"/>

        <button type="submit" class="rounded-full bg-sky-500 p-2">Login</button>
        </.form>
      </div>
    <div class="toggle-box absolute top-0 left-1/2 w-full h-full z-10 overflow-hidden transition-all duration-[600ms] ease-in-out group-[.active]:-translate-x-full rounded-l-[150px] group-[.active]:rounded-l-none group-[.active]:rounded-r-[150px]">
        <div class="absolute h-full w-[300%] left-[-100%] bg-gradient-to-r from-sky-500 via-indigo-950 to-slate-950 text-white transition-transform duration-[600ms] ease-in-out group-[.active]:translate-x-1/2">
        </div>
        <div class="toggle-panel login absolute w-1/2 h-full flex flex-col justify-center items-center px-8 text-center top-0 transition-all duration-600 ease-in-out left-0 group-[.active]:-left-1/2 delay-300">
            <h1 class="text-xl font-bold">Hii Uso ni Familiar</h1>
            <p class="mb-5">Go ahead and login</p>
            <button phx-click={JS.add_class("active", to: ".container")} class="log-btn w-40 h-11 bg-transparent rounded-full border-2 border-white shadow-none">Log In</button>
        </div>
        <div class="toggle-panel register absolute w-1/2 h-full flex flex-col justify-center items-center px-8 text-center top-0 transition-all duration-600 ease-in-out -right-1/2 group-[.active]:right-0 group-[.active]:delay-300">
            <h1 class="text-xl font-bold">Not Part of the Family?</h1>
            <p class="mb-5">Go ahead and register</p>
            <button phx-click={JS.remove_class("active", to: ".container")} class="reg-btn w-40 h-11 bg-transparent rounded-full border-2 border-white shadow-none">Sign Up</button>
        </div>
      </div>
    </div>
    """
  end
end
