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
    plug :fetch_current_user_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KameramaniPhxWeb do
    pipe_through :browser

    # Grouped in a live_session to allow seamless navigation
    live_session :public, on_mount: [{KameramaniPhxWeb.UserAuth, :mount_current_user}] do
      live "/", LandingLive, :index
      live "/auth", NewAuthLive
      live "/watch/:stream_id", ChatLive, :index
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

  ## Authentication routes

  scope "/", KameramaniPhxWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{KameramaniPhxWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/studio", StudioLive
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", KameramaniPhxWeb do
    pipe_through [:browser]

    # Fixed: Point to the 'new' action in your controller
    # The controller will then handle the redirect to ~p"/auth"
    get "/users/log-in", UserSessionController, :new

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
