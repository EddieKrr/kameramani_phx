defmodule KameramaniPhxWeb.Router do
  use KameramaniPhxWeb, :router

  import KameramaniPhxWeb.UserAuth
  # alias KameramaniPhxWeb.Settings # Removed
  # alias KameramaniPhxWeb.Profile # Removed

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KameramaniPhxWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user_for_user
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

    live_session :default,
      on_mount: [{KameramaniPhxWeb.UserAuth, :mount_current_user}],
      layout: {KameramaniPhxWeb.Layouts, :app} do
      live "/", LandingLive, :index
      live "/watch/:username", ChatLive, :show
      live "/register", AuthLive
      live "/categories", CategoryLive
      live "/users/settings", UserLive.UserSettingsLive, :edit
      live "/studio", StudioLive
      live "/directory", DirectoryLive, :index
      live "/directory/:slug", DirectoryLive, :show
    end

    live_session :auth_pages,
      layout: {KameramaniPhxWeb.Layouts, :auth},
      on_mount: [{KameramaniPhxWeb.UserAuth, :mount_current_user}] do
      live "/auth", NewAuthLive
    end

    # Login/Logout logic
    get "/users/log-in", UserSessionController, :new
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # =========================================================
  # PROTECTED ROUTES (Must be logged in)
  # =========================================================
  # Removed KameramaniPhxWeb from scope argument
  scope "/" do
    # 2. USE THE RENAMED PIPELINE HERE
    pipe_through [:browser, :require_auth]

    # Full module name
    post "/users/update-password", KameramaniPhxWeb.UserSessionController, :update_password

    # 3. LIVE SESSION FOR AUTH USERS
    live_session :require_authenticated_user,
      on_mount: [{KameramaniPhxWeb.UserAuth, :require_authenticated}],
      layout: {KameramaniPhxWeb.Layouts, :app} do
      # I moved ChatLive here assuming you want chatting to be private.
      # If you want it public, move it back to the top scope!
      live "/users/profile/:username", KameramaniPhxWeb.Profile.UserProfileLive, :show
      live "/users/settings", KameramaniPhxWeb.UserLive.UserSettingsLive
      live "/users/settings/stream-key", KameramaniPhxWeb.Streaming.Settings.StreamKeyLive

      live "/users/settings/confirm-email/:token",
           KameramaniPhxWeb.UserLive.UserSettingsLive,
           :confirm_email

      live "/studio", KameramaniPhxWeb.StudioLive
      live "/stream-settings", KameramaniPhxWeb.Streaming.Settings.StreamSettingsLive
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
