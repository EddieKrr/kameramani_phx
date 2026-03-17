defmodule KameramaniPhx.Accounts.UserNotifier do
  import Swoosh.Email

  alias KameramaniPhx.Mailer
  alias KameramaniPhx.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"KameramaniPhx", "onboarding@resend.dev"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver welcome email after registration.
  """
  def deliver_welcome_email(user) do
    deliver(user.email, "Welcome to KameramaniPhx!", """

    ==============================

    Hi #{user.username || user.email},

    Welcome to KameramaniPhx! We're excited to have you as part of our community.

    Start exploring and enjoy your time on the platform!

    ==============================
    """)
  end

  @doc """
  Deliver notification for verification request submitted.
  """
  def deliver_verification_submitted(user) do
    deliver(user.email, "Verification Request Submitted", """

    ==============================

    Hi #{user.username || user.email},

    Your request for account verification has been submitted and is currently being reviewed by our team.

    We will notify you once a decision has been made.

    ==============================
    """)
  end

  @doc """
  Deliver notification for verification request approved.
  """
  def deliver_verification_approved(user) do
    deliver(user.email, "Verification Request Approved!", """

    ==============================

    Hi #{user.username || user.email},

    Congratulations! Your account verification request has been approved. 
    You now have a verified badge on your profile.

    ==============================
    """)
  end

  @doc """
  Deliver notification for verification request rejected.
  """
  def deliver_verification_rejected(user) do
    deliver(user.email, "Verification Request Update", """

    ==============================

    Hi #{user.username || user.email},

    Thank you for your interest in verifying your account. 
    After reviewing your request, we are unable to approve it at this time.

    If you have any questions, please contact our support team.

    ==============================
    """)
  end

  @doc """
  Deliver notification for user ban.
  """
  def deliver_user_banned(user, reason) do
    deliver(user.email, "Account Status Update", """

    ==============================

    Hi #{user.username || user.email},

    Your account has been banned for the following reason:
    #{reason}

    If you believe this was a mistake, please contact our support team.

    ==============================
    """)
  end

  @doc """
  Deliver notification for user warning.
  """
  def deliver_user_warned(user, message) do
    deliver(user.email, "Account Warning", """

    ==============================

    Hi #{user.username || user.email},

    This is a formal warning regarding your account activity:
    #{message}

    Please ensure you follow our community guidelines to avoid further actions.

    ==============================
    """)
  end

  @doc """
  Deliver generic system update notification.
  """
  def deliver_system_update(user, update_message) do
    deliver(user.email, "System Update", """

    ==============================

    Hi #{user.username || user.email},

    We have an important update regarding KameramaniPhx:

    #{update_message}

    ==============================
    """)
  end
end
