defmodule KameramaniPhxWeb.UserLive.Settings do
  use KameramaniPhxWeb, :live_view

  on_mount {KameramaniPhxWeb.UserAuth, :require_sudo_mode}

  alias KameramaniPhx.Accounts


  @impl true
  def mount(%{"token" => token}, _session, socket) do
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
    user = socket.assigns.current_scope.user
    email_changeset = KameramaniPhx.Accounts.User.email_changeset(user, %{email: user.email}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    profile_changeset = Accounts.change_user_profile(user, %{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_user.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
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

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_user.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  # updating user profile picture and bio
def handle_event("update_dp", %{"user" => user_params}, socket) do
  user = socket.assigns.current_user.user

  # Ensure the upload key matches your allow_upload name (was :avatar in previous examples, now :profile_picture)
  image_upload =
    consume_uploaded_entries(socket, :profile_picture, fn %{path: path}, _entry ->
      # Note: fixed typo .pgn -> .png
      desti = Path.join(["priv", "static", "uploads", "#{user.id}-profile.png"])
      File.cp!(path, desti)
      {:ok, "/uploads/#{Path.basename(desti)}"}
    end)

  # Explicitly merge the params
  final_params =
    if url = List.first(image_upload) do
      Map.put(user_params, "profile_picture", url)
    else
      user_params
    end

  case Accounts.update_user_profile(user, final_params) do
    {:ok, updated_user} ->
      socket =
        socket
        |> put_flash(:info, "Profile updated successfully.")
        |> assign(:profile_form, to_form(Accounts.change_user_profile(updated_user, %{})))

      {:noreply, socket}

    {:error, changeset} ->
      {:noreply, assign(socket, profile_form: to_form(changeset))}
  end
end
end
