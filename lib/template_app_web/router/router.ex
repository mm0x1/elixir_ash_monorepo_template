defmodule TemplateAppWeb.Router do
  use TemplateAppWeb, :router
  use AshAuthentication.Phoenix.Router

  import TemplateAppWeb.Helpers.InertiaHelpers, only: [info_flash: 2]

  alias TemplateAppWeb.Plugs.EnsureAuthenticatedPlug
  alias TemplateAppWeb.Plugs.EnsureAdminPlug
  alias TemplateAppWeb.Plugs.AppConfigPropPlug

  alias TemplateAppWeb.Helpers.ConnHelpers

  defp redirect_if_authenticated(conn, _opts) do
    if ConnHelpers.get_current_user(conn) do
      conn
      |> info_flash("You are already signed in.")
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TemplateAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
    plug Inertia.Plug
    plug TemplateAppWeb.Plugs.CurrentUserPropPlug
    plug AppConfigPropPlug
  end

  pipeline :require_authenticated_user do
    plug EnsureAuthenticatedPlug
  end

  pipeline :require_unauthenticated_user do
    plug :redirect_if_authenticated
  end

  pipeline :require_admin do
    plug EnsureAdminPlug
  end

  # API pipeline for JSON-only endpoints (no session/CSRF)
  pipeline :api do
    plug :accepts, ["json"]
  end

  # Log ingestion endpoint (rate limited, no auth required)
  scope "/api", TemplateAppWeb.Api do
    pipe_through [:api]

    post "/logs", LogController, :create
  end

  # Authentication API routes (public)
  scope "/api/auth", TemplateAppWeb do
    pipe_through [:browser]

    post "/register", AuthApiController, :register
    post "/sign-in", AuthApiController, :sign_in
    delete "/session", AuthApiController, :sign_out
    post "/anonymous", AuthApiController, :create_anonymous
    post "/reset-password", AuthApiController, :reset_password
  end

  # Authentication API routes (requires auth)
  scope "/api/auth", TemplateAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/recovery-codes", AuthApiController, :generate_recovery_codes
    post "/convert", AuthApiController, :convert_to_registered
  end

  # RPC endpoint for ash_typescript client-side data fetching
  scope "/rpc", TemplateAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/run", RpcController, :run
    post "/validate", RpcController, :validate
  end

  # ------ INERTIA JS ROUTES ONLY ------ #

  scope "/", TemplateAppWeb do
    pipe_through [:browser]

    get "/", PageController, :home
  end

  scope "/", TemplateAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/profile", ProfileController, :show_profile
  end

  scope "/auth", TemplateAppWeb do
    pipe_through [:browser, :require_unauthenticated_user]

    get "/sign-in", AuthController, :show_login
    get "/complete", AuthController, :complete_authentication
    get "/reset-password", AuthController, :show_reset_password

    if TemplateApp.Config.registration_enabled?() do
      get "/registration/new", AuthController, :show_registration
    end
  end

  scope "/auth", TemplateAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/session/sign-out", AuthController, :show_sign_out
    get "/recovery-codes", AuthController, :show_recovery_codes
    get "/convert", AuthController, :show_convert
  end

  # ------ INERTIA JS ROUTES ONLY END ------ #

  if Application.compile_env(:template_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router
    import AshAdmin.Router

    scope "/dev" do
      pipe_through [:browser]

      live_dashboard "/dashboard", metrics: TemplateAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/admin" do
      pipe_through [:browser, :require_authenticated_user, :require_admin]

      ash_admin "/"
    end
  end
end
