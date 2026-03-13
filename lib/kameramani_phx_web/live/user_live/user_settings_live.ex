defmodule KameramaniPhxWeb.UserLive.UserSettingsLive do
  use KameramaniPhxWeb, :live_view

  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Socials
  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      assign(
        socket,
        :social_form,
        to_form(Socials.change_social_account(%Socials.SocialAccount{}))
      )

    socket =
      case Accounts.update_user_email(socket.assigns.current_user.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user.user

    email_changeset =
      Accounts.User.email_changeset(user, %{email: user.email}, validate_unique: false)

    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    profile_changeset = Accounts.change_user_profile(user, %{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:social_form, to_form(Socials.change_social_account(%Socials.SocialAccount{})))
      |> assign(:user_socials, Socials.list_user_socials(user))
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", %{"user" => user_params}, socket) do
    email_form =
      socket.assigns.current_user.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", %{"user" => user_params}, socket) do
    password_form =
      socket.assigns.current_user.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    profile_form =
      socket.assigns.current_user.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user.user

    # Handle file uploads
    uploaded_files =
      consume_uploaded_entries(socket, :profile_picture, fn %{path: path}, _entry ->
        # Use simple project-relative path for local development
        dest_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(dest_dir)

        filename = "#{user.id}-#{System.system_time(:millisecond)}.png"
        dest_path = Path.join(dest_dir, filename)

        File.cp!(path, dest_path)
        {:ok, "/uploads/#{filename}"}
      end)

    # If a file was uploaded, add it to params; otherwise keep existing
    final_params =
      case List.first(uploaded_files) do
        nil -> user_params
        url -> Map.put(user_params, "profile_picture", url)
      end

    case Accounts.update_user_profile(user, final_params) do
      {:ok, updated_user} ->
        # Update socket state so the UI reflects changes immediately
        socket =
          socket
          |> put_flash(:info, "Profile updated successfully.")
          |> assign(:profile_form, to_form(Accounts.change_user_profile(updated_user, %{})))
          |> assign(:current_user, %{socket.assigns.current_user | user: updated_user})
          |> push_navigate(to: ~p"/users/profile/#{updated_user.username}")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :profile_picture, ref)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, page_title: "Settings")}
  end
end
