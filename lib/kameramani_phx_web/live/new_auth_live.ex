defmodule KameramaniPhxWeb.NewAuthLive do
  use KameramaniPhxWeb, :live_view

  on_mount {KameramaniPhxWeb.UserAuth, :mount_current_scope}

  import Phoenix.LiveView

  import Phoenix.LiveView
  alias KameramaniPhx.Accounts
  import RegComponents
  import LogComponents

  def mount(params, _session, socket) do
    reg_changeset = Accounts.validate_registration(%{})
    log_form = to_form(%{"email" => "", "password" => ""}, as: "user")

    active_panel =
      case Map.get(params, "panel") do
        "login" -> :login
        _ -> :register
      end

    socket =
      socket
      |> assign(
        reg_form: to_form(reg_changeset, as: "reg"),
        log_form: log_form,
        show_password: false,
        active_panel: active_panel
      )

    {:ok, socket}
  end

  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, show_password: not socket.assigns.show_password)}
  end

  def handle_event("set_panel_login", _params, socket) do
    {:noreply, assign(socket, active_panel: :login)}
  end

  def handle_event("set_panel_register", _params, socket) do
    {:noreply, assign(socket, active_panel: :register)}
  end

  def handle_event("validate_reg", %{"reg" => user_params}, socket) do
    changeset = Accounts.validate_registration(user_params)
    {:noreply, assign(socket, reg_form: to_form(changeset, as: "reg"))}
  end

  def handle_event("register", %{"reg" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Registration successful! Please log in.")
         |> push_navigate(to: ~p"/auth?panel=login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, reg_form: to_form(changeset, as: "reg"))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class={"flex flex-row container group mx-auto my-18 relative w-[768px] max-w-full min-h-[480px] bg-indigo-200 rounded-[30px] shadow-2xl overflow-hidden #{if @active_panel == :login, do: "active", else: ""}"}>
      <div class="form-register flex w-1/2">
        <.form
          for={@reg_form}
          phx-change="validate_reg"
          phx-submit="register"
          class="flex flex-col justify-right m-auto text-black gap-3 p-2 rounded-2xl"
        >
          <.mesage field={@reg_form[:name]} placeholder="Name" />
          <.mesage field={@reg_form[:username]} placeholder="Username" />
          <.mesage field={@reg_form[:email]} placeholder="Email" />
          <.mesage field={@reg_form[:age]} placeholder="Age" />
          <.mesage field={@reg_form[:password]} placeholder="Password" type={if @show_password, do: "text", else: "password"} />
          <button type="button" phx-click="toggle_password" class="rounded-full bg-indigo-500 text-white p-1 mt-1">
            <%= if @pass_visible, do: "Hide", else: "Show" %> Password
          </button>

          <button type="submit" class="rounded-full bg-indigo-700 text-white p-2">
            Register
          </button>
        </.form>
      </div>
      <div class="form-login flex w-1/2">
        <form
          action={~p"/users/log-in"}
          method="post"
          class="flex flex-col m-auto gap-2"
        >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <.log field={@log_form[:email]} placeholder="Email" name="user[email]" />
          <.log field={@log_form[:password]} placeholder="Password" name="user[password]" type={if @show_password, do: "text", else: "password"} />
          <button type="button" phx-click="toggle_key" class="rounded-full bg-sky-500 text-white p-1 mt-1">
            <%= if @show_password, do: "Hide", else: "Show" %> Password
          </button>

          <button type="submit" class="rounded-full bg-sky-500 p-2">
            Login
          </button>
        </form>
      </div>
      <div class="toggle-box absolute top-0 left-1/2 w-full h-full z-10 overflow-hidden transition-all duration-[600ms] ease-in-out group-[.active]:-translate-x-full rounded-l-[150px] group-[.active]:rounded-l-none group-[.active]:rounded-r-[150px]">
        <div class="absolute h-full w-[300%] left-[-100%] bg-gradient-to-r from-sky-500 via-indigo-950 to-slate-950 text-white transition-transform duration-[600ms] ease-in-out group-[.active]:translate-x-1/2"></div>
        <div class="toggle-panel login absolute w-1/2 h-full flex flex-col justify-center items-center px-8 text-center top-0 transition-all duration-600 ease-in-out left-0 group-[.active]:-left-1/2 delay-300">
          <h1 class="text-xl font-bold">Hii Uso ni Familiar</h1>
          <p class="mb-5">Go ahead and login</p>
          <button phx-click="set_panel_login" class="log-btn w-40 h-11 bg-transparent rounded-full border-2 border-white shadow-none">Log In</button>
        </div>
        <div class="toggle-panel register absolute w-1/2 h-full flex flex-col justify-center items-center px-8 text-center top-0 transition-all duration-600 ease-in-out -right-1/2 group-[.active]:right-0 group-[.active]:delay-300">
          <h1 class="text-xl font-bold">Not Part of Family?</h1>
          <p class="mb-5">Go ahead and register</p>
          <button phx-click="set_panel_register" class="reg-btn w-40 h-11 bg-transparent rounded-full border-2 border-white shadow-none">Sign Up</button>
        </div>
      </div>
    </div>
    """
  end
end
