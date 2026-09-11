defmodule TemplateAppWeb.AuthController do
  @moduledoc """
  Authentication controller for hybrid token auth.

  Handles:
  - Login: Validates credentials, creates refresh token, returns access token
  - Register: Creates user, generates tokens
  - Refresh: Validates refresh token cookie, returns new access token
  - Logout: Deletes specific refresh token, clears cookie
  - Logout All: Increments user.token_version, invalidates all refresh tokens
  """

  use TemplateAppWeb, :controller
  use AshAuthentication.Phoenix.Controller

  defoverridable call: 2

  import TemplateAppWeb.Helpers.UserSerializer, only: [serialize_user: 1]

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.JWT
  alias TemplateApp.Accounts.RefreshSessions
  alias TemplateApp.Accounts.Resources.RefreshToken
  alias TemplateApp.Accounts.Validations.ValidatePasswordPolicy
  alias TemplateAppWeb.Helpers.ApiResponse
  alias TemplateAppWeb.Plugs.RateLimitPlug

  require Logger

  plug(RateLimitPlug, [action: :login] when action in [:login])
  plug(RateLimitPlug, [action: :register] when action in [:register])
  plug(RateLimitPlug, [action: :refresh] when action in [:refresh])
  plug(RateLimitPlug, [action: :reset_password] when action in [:reset_password])
  plug(RateLimitPlug, [action: :logout] when action in [:logout])

  @refresh_token_cookie "_template_app_refresh"
  @refresh_token_max_age 7 * 24 * 60 * 60

  # These callbacks serve the development-only browser session used by Ash Admin.
  # The REST login actions below remain token-based for the SPA.
  def success(conn, _activity, user, _token) do
    conn
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> redirect(to: "/admin")
  end

  def failure(conn, _activity, _reason) do
    conn
    |> put_flash(:error, "Invalid username or password")
    |> redirect(to: "/dev/admin/sign-in")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session(:template_app)
    |> redirect(to: "/dev/admin/sign-in")
  end

  def call(conn, {_subject_name, _strategy_name, :register}) do
    dev_registration_disabled(conn, %{})
  end

  def call(conn, opts), do: super(conn, opts)

  def dev_registration_disabled(conn, _params) do
    ApiResponse.forbidden(
      conn,
      "registration_disabled",
      "Registration is not available from the development admin login"
    )
  end

  def login(conn, %{"username" => username, "password" => password}) do
    if ValidatePasswordPolicy.within_max_length?(password) do
      case Accounts.sign_in(username, password) do
        {:ok, user} ->
          create_tokens_and_respond(conn, user)

        {:error, _reason} ->
          ApiResponse.unauthorized(conn, "invalid_credentials", "Invalid username or password")
      end
    else
      ApiResponse.unauthorized(conn, "invalid_credentials", "Invalid username or password")
    end
  end

  def login(conn, _params) do
    ApiResponse.bad_request(conn, "Username and password are required")
  end

  def register(conn, %{
        "username" => username,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    if TemplateApp.Config.registration_enabled?() do
      case Accounts.create_user(username, password, password_confirmation) do
        {:ok, user} ->
          create_tokens_and_respond(conn, user, 201)

        {:error, error} ->
          ApiResponse.validation_error(conn, error, "Registration failed")
      end
    else
      ApiResponse.forbidden(conn, nil, "Registration is currently disabled")
    end
  end

  def register(conn, _params) do
    ApiResponse.bad_request(
      conn,
      "Username, password, and password_confirmation are required"
    )
  end

  def refresh(conn, _params) do
    with {:ok, refresh_token_id} <- get_refresh_token_cookie(conn),
         {:ok, %{access_token: access_token, refresh_token: new_refresh_token}} <-
           RefreshSessions.rotate(refresh_token_id) do
      conn
      |> set_refresh_cookie(new_refresh_token.id)
      |> ApiResponse.success(%{
        access_token: access_token,
        expires_in: JWT.access_token_lifetime()
      })
    else
      {:error, :no_cookie} ->
        ApiResponse.unauthorized(conn, "no_refresh_token", "No refresh token found")

      {:error, :token_not_found} ->
        conn
        |> delete_refresh_cookie()
        |> ApiResponse.unauthorized("invalid_refresh_token", "Refresh token not found")

      {:error, :token_expired} ->
        conn
        |> delete_refresh_cookie()
        |> ApiResponse.unauthorized("token_expired", "Refresh token has expired")

      {:error, :token_version_mismatch} ->
        conn
        |> delete_refresh_cookie()
        |> ApiResponse.unauthorized("token_revoked", "Session has been revoked")

      {:error, :user_not_found} ->
        conn
        |> delete_refresh_cookie()
        |> ApiResponse.unauthorized("user_not_found", "User not found")

      {:error, :rotation_failed} ->
        conn
        |> delete_refresh_cookie()
        |> ApiResponse.internal_error("Failed to rotate refresh session")

      {:error, _reason} ->
        conn
        |> delete_refresh_cookie()
        |> ApiResponse.internal_error("Failed to refresh session")
    end
  end

  def logout(conn, _params) do
    case get_refresh_token_cookie(conn) do
      {:ok, refresh_token_id} ->
        case RefreshSessions.revoke(refresh_token_id) do
          {:ok, :revoked} ->
            conn
            |> delete_refresh_cookie()
            |> ApiResponse.message("Logged out successfully")

          {:ok, :already_logged_out} ->
            conn
            |> delete_refresh_cookie()
            |> ApiResponse.message("Already logged out")

          {:error, _reason} ->
            conn
            |> delete_refresh_cookie()
            |> ApiResponse.internal_error("Failed to logout session")
        end

      {:error, :no_cookie} ->
        ApiResponse.message(conn, "Already logged out")
    end
  end

  def logout_all(conn, _params) do
    user = conn.assigns.current_user

    case Ash.update(user, %{}, action: :increment_token_version, actor: user) do
      {:ok, _updated_user} ->
        conn
        |> delete_refresh_cookie()
        |> ApiResponse.message("Logged out from all devices")

      {:error, _reason} ->
        ApiResponse.internal_error(conn, "Failed to logout all devices")
    end
  end

  def me(conn, _params) do
    {:ok, user} =
      Ash.load(conn.assigns.current_user, [:has_recovery_codes, :recovery_codes_count],
        authorize?: false
      )

    ApiResponse.success(conn, %{user: serialize_user(user)})
  end

  def reset_password(conn, %{
        "username" => username,
        "recovery_code" => recovery_code,
        "new_password" => new_password
      }) do
    case fetch_user_by_username(username) do
      {:ok, user} ->
        case Accounts.reset_password_with_recovery_code(user, recovery_code, new_password) do
          {:ok, _updated} ->
            ApiResponse.message(conn, "Password reset successfully")

          {:error, _error} ->
            ApiResponse.validation_error_static(conn, "Invalid recovery code")
        end

      {:error, :not_found} ->
        Argon2.no_user_verify()
        ApiResponse.validation_error_static(conn, "Invalid recovery code")
    end
  end

  def reset_password(conn, _params) do
    ApiResponse.bad_request(
      conn,
      "Username, recovery_code, and new_password are required"
    )
  end

  # Private helpers

  defp fetch_user_by_username(username) do
    case Accounts.get_by_username(username) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, user} -> {:ok, user}
      {:error, _} -> {:error, :not_found}
    end
  end

  defp create_tokens_and_respond(conn, user, status \\ 200) do
    with {:ok, user} <-
           Ash.load(user, [:has_recovery_codes, :recovery_codes_count], authorize?: false),
         {:ok, access_token} <- JWT.generate_access_token(user),
         {:ok, refresh_token} <- create_refresh_token(conn, user) do
      conn
      |> set_refresh_cookie(refresh_token.id)
      |> ApiResponse.success(
        %{
          access_token: access_token,
          expires_in: JWT.access_token_lifetime(),
          user: serialize_user(user)
        },
        status
      )
    else
      {:error, _reason} ->
        Logger.error("Failed to create authentication tokens", error_category: "authentication")
        ApiResponse.internal_error(conn, "Failed to create authentication tokens")
    end
  end

  defp create_refresh_token(conn, user) do
    device_name = get_device_name(conn)

    RefreshToken
    |> Ash.Changeset.for_create(:create, %{
      user_id: user.id,
      device_name: device_name,
      version: user.token_version
    })
    |> Ash.create()
  end

  defp get_device_name(conn) do
    case get_req_header(conn, "user-agent") do
      [ua | _] -> String.slice(ua, 0, 255)
      _ -> nil
    end
  end

  defp get_refresh_token_cookie(conn) do
    case conn.cookies[@refresh_token_cookie] do
      nil -> {:error, :no_cookie}
      "" -> {:error, :no_cookie}
      token_id -> {:ok, token_id}
    end
  end

  defp set_refresh_cookie(conn, token_id) do
    put_resp_cookie(conn, @refresh_token_cookie, token_id,
      http_only: true,
      secure: secure_cookies?(),
      same_site: refresh_cookie_same_site(),
      max_age: @refresh_token_max_age,
      path: "/"
    )
  end

  defp delete_refresh_cookie(conn) do
    delete_resp_cookie(conn, @refresh_token_cookie,
      path: "/",
      secure: secure_cookies?(),
      same_site: refresh_cookie_same_site()
    )
  end

  defp secure_cookies? do
    Application.get_env(
      :template_app,
      :secure_cookies,
      Application.get_env(:template_app, :env) == :prod
    )
  end

  defp refresh_cookie_same_site do
    Application.get_env(:template_app, :refresh_cookie_same_site, "Lax")
  end
end
