defmodule KameramaniPhxWeb.Router do
  use KameramaniPhxWeb, :router

  import KameramaniPhxWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KameramaniPhxWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # 1. DEFINE THE MISSING PIPELINE
  # We name it :require_auth to avoid clashing with the imported function
  pipeline :require_auth do
    plug :require_authenticated_user
  end

  # =========================================================
  # PUBLIC ROUTES (Guests can see these)
  # =========================================================
  scope "/", KameramaniPhxWeb do
    pipe_through [:browser]

    live "/", LandingLive, :index
    live "/auth", NewAuthLive
    live "/register", AuthLive

    # Login/Logout logic
    get "/users/log-in", UserSessionController, :new
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # =========================================================
  # PROTECTED ROUTES (Must be logged in)
  # =========================================================
  scope "/", KameramaniPhxWeb do
    # 2. USE THE RENAMED PIPELINE HERE
    pipe_through [:browser, :require_auth]

    post "/users/update-password", UserSessionController, :update_password

    # 3. LIVE SESSION FOR AUTH USERS
    live_session :require_authenticated_user,
      on_mount: [{KameramaniPhxWeb.UserAuth, :require_authenticated}] do

      # I moved ChatLive here assuming you want chatting to be private.
      # If you want it public, move it back to the top scope!
      live "/watch/:stream_id", ChatLive, :show

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/studio", StudioLive
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:kameramani_phx, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KameramaniPhxWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
