defmodule KameramaniPhxWeb.AdminLive do
  use KameramaniPhxWeb, :live_view
  import KameramaniPhxWeb.AdminComponents

  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Streaming
  alias KameramaniPhx.Content

  @users_page_size 6
  @streams_page_size 6

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "streams:all")
      Phoenix.PubSub.subscribe(KameramaniPhx.PubSub, "admin:verifications")
    end

    current_user = socket.assigns.current_user.user

    all_menu_items = [
      %{id: "users", label: "Users", path: ~p"/admin/users"},
      %{id: "streams", label: "Live Streams", path: ~p"/admin/streams"},
      %{id: "verification", label: "Verification", path: ~p"/admin/verification"},
      %{id: "categories", label: "Categories", path: ~p"/admin/categories"},
      %{id: "tags", label: "Tags", path: ~p"/admin/tags"},
      %{id: "access", label: "Access Control", path: ~p"/admin/access"},
      %{id: "settings", label: "Settings", path: ~p"/admin/settings"}
    ]

    is_moderator = KameramaniPhx.Accounts.user_has_role?(current_user, "moderator")

    menu_items =
      if is_moderator do
        Enum.reject(all_menu_items, &(&1.id in ["access", "settings"]))
      else
        all_menu_items
      end

    active_tab = "users"

    {:ok, assign(socket,
        layout_type: :admin,
        active_tab: active_tab,
        allowed_tabs: Enum.map(menu_items, & &1.id),
        users_page: nil,
        live_streams_page: nil,
        verification_requests: [],
        menu_items: menu_items,
        page_bg_class: "bg-slate-900",
        show_add_user_modal: false,
        user_to_edit: nil,
        add_user_form: to_form(Accounts.validate_registration(%{})),
        show_add_category_modal: false,
        add_category_form: to_form(Content.change_category(%KameramaniPhx.Content.Category{}))
      )}
  end

  @impl true
  def handle_event("open_add_user_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(show_add_user_modal: true, user_to_edit: nil, add_user_form: to_form(Accounts.validate_registration(%{})))}
  end

  @impl true
  def handle_event("edit_user", %{"id" => id}, socket) do
    case Accounts.get_user!(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "User not found")}

      user ->
        {:noreply,
         socket
         |> assign(
           show_add_user_modal: true,
           user_to_edit: user,
           add_user_form: to_form(Accounts.change_user(user))
         )}
    end
  end

  @impl true
  def handle_event("close_add_user_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(show_add_user_modal: false, user_to_edit: nil)}
  end

  @impl true
  def handle_event("validate_user", %{"user" => user_params}, socket) do
    changeset =
      if user = socket.assigns.user_to_edit do
        Accounts.change_user(user, user_params)
      else
        Accounts.validate_registration(user_params)
      end

    {:noreply, assign(socket, add_user_form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save_user", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.user_to_edit, user_params)
  end

  @impl true
  def handle_event("open_add_category_modal", _params, socket) do
    {:noreply, assign(socket, show_add_category_modal: true)}
  end

  @impl true
  def handle_event("close_add_category_modal", _params, socket) do
    {:noreply, assign(socket, show_add_category_modal: false)}
  end

  @impl true
  def handle_event("validate_category", %{"category" => category_params}, socket) do
    form =
      %KameramaniPhx.Content.Category{}
      |> Content.change_category(category_params)
      |> to_form(action: :validate)

    {:noreply, assign(socket, add_category_form: form)}
  end

  @impl true
  def handle_event("save_category", %{"category" => category_params}, socket) do
    case Content.create_category(category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created successfully")
         |> assign(
           show_add_category_modal: false,
           add_category_form: to_form(Content.change_category(%KameramaniPhx.Content.Category{}))
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, add_category_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("approve_verification", %{"id" => id}, socket) do
    request = Accounts.get_verification_request!(id)

    case Accounts.approve_verification_request(request) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User verified successfully")
         |> assign(verification_requests: Accounts.list_pending_verification_requests())}

      {:error, _, _, _} ->
        {:noreply, put_flash(socket, :error, "Could not verify user")}
    end
  end

  @impl true
  def handle_event("reject_verification", %{"id" => id}, socket) do
    request = Accounts.get_verification_request!(id)

    case Accounts.reject_verification_request(request) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Verification request rejected")
         |> assign(verification_requests: Accounts.list_pending_verification_requests())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not reject request")}
    end
  end

  @impl true
  def handle_event("paginate_users", %{"page" => page}, socket) do
    page_number = page_param(page, socket.assigns.users_page.page_number)

    users_page =
      Accounts.get_all_users(page: page_number, page_size: @users_page_size)

    {:noreply, assign(socket, users_page: users_page)}
  end

  @impl true
  def handle_event("paginate_streams", %{"page" => page}, socket) do
    page_number = page_param(page, socket.assigns.live_streams_page.page_number)

    live_streams_page =
      Streaming.list_live_streams(page: page_number, page_size: @streams_page_size)

    {:noreply, assign(socket, live_streams_page: live_streams_page)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    current_tab = Map.get(params, "tab", "users")

    if current_tab in socket.assigns.allowed_tabs do
      socket =
        case current_tab do
          "users" ->
            assign(socket, users_page: Accounts.get_all_users(page: 1, page_size: @users_page_size))

          "streams" ->
            assign(socket,
              live_streams_page: Streaming.list_live_streams(page: 1, page_size: @streams_page_size)
            )

          "verification" ->
            assign(socket, verification_requests: Accounts.list_pending_verification_requests())

          _ ->
            socket
        end

      {:noreply, assign(socket, active_tab: current_tab)}
    else
      fallback_tab = "users"

      {:noreply,
       socket
       |> put_flash(:error, "You do not have access to that admin section.")
       |> push_patch(to: ~p"/admin/#{fallback_tab}")}
    end
  end

  @impl true
  def handle_info(:verification_request_submitted, socket) do
    socket =
      if socket.assigns.active_tab == "verification" do
        assign(socket, verification_requests: Accounts.list_pending_verification_requests())
      else
        socket
      end

    {:noreply, put_flash(socket, :info, "New verification request submitted!")}
  end

  @impl true
  def handle_info({:stream_status_updated, updated_stream}, socket) do
    socket =
      if socket.assigns.users_page do
        entries =
          Enum.map(socket.assigns.users_page.entries, fn user ->
            if user.id == updated_stream.user_id do
              %{user | is_live: updated_stream.is_live}
            else
              user
            end
          end)

        assign(socket, users_page: %{socket.assigns.users_page | entries: entries})
      else
        socket
      end

    socket =
      if socket.assigns.live_streams_page do
        live_streams_page =
          Streaming.list_live_streams(
            page: socket.assigns.live_streams_page.page_number,
            page_size: @streams_page_size
          )

        assign(socket, live_streams_page: live_streams_page)
      else
        socket
      end

    {:noreply, socket}
  end

  defp page_param(value, default) do
    case Integer.parse(to_string(value || "")) do
      {int, ""} when int >= 1 ->
        int

      _ ->
        default || 1
    end
  end

  defp save_user(socket, nil, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        users_page = Accounts.get_all_users(page: 1, page_size: @users_page_size)

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> assign(
           show_add_user_modal: false,
           add_user_form: to_form(Accounts.validate_registration(%{})),
           users_page: users_page
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not create user")
         |> assign(add_user_form: to_form(changeset))}
    end
  end

  defp save_user(socket, user, user_params) do
    case Accounts.update_user(user, user_params) do
      {:ok, _user} ->
        users_page =
          Accounts.get_all_users(
            page: socket.assigns.users_page.page_number,
            page_size: @users_page_size
          )

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> assign(
           show_add_user_modal: false,
           user_to_edit: nil,
           users_page: users_page
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not update user")
         |> assign(add_user_form: to_form(changeset))}
    end
  end
end
