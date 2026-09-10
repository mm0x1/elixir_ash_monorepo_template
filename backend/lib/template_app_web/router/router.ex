defmodule TemplateAppWeb.Router do
  use TemplateAppWeb, :router
  use AshAuthentication.Phoenix.Router

  alias TemplateAppWeb.Plugs.EnsureAuthenticatedPlug
  alias TemplateAppWeb.Plugs.EnsureAdminPlug
  alias TemplateAppWeb.Plugs.ValidateAccessToken
  alias TemplateAppWeb.Helpers.ConnHelpers

  defp redirect_if_authenticated(conn, _opts) do
    if ConnHelpers.get_current_user(conn) do
      conn
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end

  # Browser pipeline for admin/dev routes (session-based)
  pipeline :browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:load_from_session)
  end

  pipeline :require_authenticated_user do
    plug(EnsureAuthenticatedPlug)
  end

  pipeline :require_unauthenticated_user do
    plug(:redirect_if_authenticated)
  end

  pipeline :require_admin do
    plug(EnsureAdminPlug)
  end

  # API pipeline for JSON-only endpoints with CORS
  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_cookies)
    plug(CORSPlug)
  end

  # Token-based authentication pipeline
  pipeline :authenticated_api do
    plug(ValidateAccessToken)
  end

  # Public auth endpoints (no token required)
  scope "/auth", TemplateAppWeb do
    pipe_through([:api])

    post("/login", AuthController, :login)
    post("/register", AuthController, :register)
    post("/refresh", AuthController, :refresh)
    post("/reset-password", AuthController, :reset_password)
  end

  # Authenticated auth endpoints (token required)
  scope "/auth", TemplateAppWeb do
    pipe_through([:api, :authenticated_api])

    post("/logout", AuthController, :logout)
    post("/logout_all", AuthController, :logout_all)
    get("/me", AuthController, :me)
  end

  # Authenticated account self-service endpoints (former RPC user ops over REST)
  scope "/account", TemplateAppWeb do
    pipe_through([:api, :authenticated_api])

    patch("/username", AccountController, :update_username)
    post("/recovery-codes", AccountController, :generate_recovery_codes)
    post("/convert", AccountController, :convert)
  end

  # Health check endpoint
  scope "/", TemplateAppWeb do
    pipe_through([:api])

    get("/health", HealthController, :index)
  end

  if Application.compile_env(:template_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router
    import AshAdmin.Router

    # Ash Admin uses a browser session, while the SPA uses bearer tokens. Keep a
    # small development-only sign-in surface for the seeded admin accounts.
    scope "/", TemplateAppWeb do
      pipe_through([:browser])

      sign_in_route(
        path: "/dev/admin/sign-in",
        auth_routes_prefix: "/dev/admin/auth",
        resources: [TemplateApp.Accounts.Resources.User],
        overrides: [
          TemplateAppWeb.AuthOverrides,
          AshAuthentication.Phoenix.Overrides.Default
        ]
      )

      auth_routes(AuthController, TemplateApp.Accounts.Resources.User, path: "/dev/admin/auth")

      sign_out_route(AuthController, "/dev/admin/sign-out", as: :admin_auth)
    end

    scope "/dev" do
      pipe_through([:browser])

      live_dashboard("/dashboard", metrics: TemplateAppWeb.Telemetry)
    end

    scope "/admin" do
      pipe_through([:browser, :require_authenticated_user, :require_admin])

      ash_admin("/")
    end
  end

  if Application.compile_env(:template_app, :serve_frontend, false) do
    get("/*path", TemplateAppWeb.FrontendController, :index)
  end
end
