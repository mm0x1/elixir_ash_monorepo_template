defmodule TemplateAppWeb.Router do
  use TemplateAppWeb, :router
  use AshAuthentication.Phoenix.Router

  alias TemplateAppWeb.Plugs.EnsureAuthenticatedPlug
  alias TemplateAppWeb.Plugs.EnsureAdminPlug
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
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
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

  # RPC endpoint for ash_typescript client-side data fetching
  # TODO: Update to use token-based auth instead of browser pipeline
  scope "/rpc", TemplateAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/run", RpcController, :run
    post "/validate", RpcController, :validate
  end

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
