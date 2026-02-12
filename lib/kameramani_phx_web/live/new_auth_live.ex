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

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(page_title: "Authentication")}
  end
end
