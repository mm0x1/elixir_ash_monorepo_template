defmodule TemplateAppWeb.AuthController do
  @moduledoc """
  Manages authentication - sign-in, registration, sign-out.

  Security: Login errors use generic messages to prevent username enumeration.
  """

  use TemplateAppWeb, :controller
  use AshAuthentication.Phoenix.Controller

  alias TemplateApp.Config

  require Logger

  plug :ensure_feature_enabled,
       :registration when action in [:show_registration, :create_registration]

  defp ensure_feature_enabled(conn, :registration) do
    if Config.registration_enabled?() do
      conn
    else
      conn
      |> put_status(:not_found)
      |> put_view(json: Phoenix.Controller.ErrorJSON)
      |> render(:"404")
      |> halt()
    end
  end

  defp get_route_path(component) do
    "Authentication/#{component}"
  end

  def show_login(conn, _params) do
    conn
    |> assign_prop(:title, "Sign In")
    |> render_inertia(get_route_path("SignIn"))
  end

  def show_registration(conn, _params) do
    conn
    |> assign_prop(:title, "Register")
    |> render_inertia(get_route_path("Registration"))
  end

  def show_sign_out(conn, _params) do
    conn
    |> assign_prop(:title, "Sign Out")
    |> render_inertia(get_route_path("SignOut"))
  end

  # AshAuthentication.Phoenix.Controller callback - delegates to show_sign_out/2
  @impl true
  def sign_out(conn, params), do: show_sign_out(conn, params)

  def complete_authentication(conn, _params) do
    conn
    |> assign_prop(:title, "Welcome")
    |> render_inertia(get_route_path("Complete"))
  end

  def show_reset_password(conn, _params) do
    conn
    |> assign_prop(:title, "Reset Password")
    |> render_inertia(get_route_path("ResetPassword"))
  end

  def show_recovery_codes(conn, params) do
    conn
    |> assign_prop(:title, "Recovery Codes")
    |> assign_prop(:first_time, params["first_time"] == "true")
    |> render_inertia(get_route_path("RecoveryCodes"))
  end

  def show_convert(conn, _params) do
    conn
    |> assign_prop(:title, "Create Account")
    |> render_inertia(get_route_path("ConvertAccount"))
  end
end
