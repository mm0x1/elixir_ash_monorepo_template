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

  import TemplateAppWeb.Helpers.UserSerializer, only: [serialize_user: 1, format_ash_errors: 1]

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.JWT
  alias TemplateApp.Accounts.Resources.RefreshToken
  alias TemplateAppWeb.Helpers.ApiResponse

  require Ash.Query
  require Logger

  @refresh_token_cookie "_template_app_refresh"
  @refresh_token_max_age 7 * 24 * 60 * 60

  @doc """
  Authenticate user with username/password and return tokens.
  """
  def login(conn, %{"username" => username, "password" => password}) do
    case Accounts.sign_in(username, password) do
      {:ok, user} ->
        create_tokens_and_respond(conn, user)

      {:error, _reason} ->
        conn
        |> put_status(401)
        |> json(%{error: "invalid_credentials", message: "Invalid username or password"})
    end
  end

  def login(conn, _params) do
    ApiResponse.bad_request(conn, "Username and password are required")
  end

  @doc """
  Register a new user with username/password.
  """
  def register(conn, %{
        "username" => username,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    case Accounts.create_user(username, password, password_confirmation) do
      {:ok, user} ->
        create_tokens_and_respond(conn, user, 201)

      {:error, error} ->
        ApiResponse.validation_error(conn, error, "Registration failed")
    end
  end

  def register(conn, _params) do
    ApiResponse.bad_request(
      conn,
      "Username, password, and password_confirmation are required"
    )
  end

  @doc """
  Refresh the access token using the refresh token from cookie.
  """
  def refresh(conn, _params) do
    with {:ok, refresh_token_id} <- get_refresh_token_cookie(conn),
         {:ok, refresh_token} <- get_valid_refresh_token(refresh_token_id),
         {:ok, user} <- load_user_for_refresh(refresh_token) do
      # Generate new access token
      case JWT.generate_access_token(user) do
        {:ok, access_token} ->
          json(conn, %{
            access_token: access_token,
            expires_in: JWT.access_token_lifetime()
          })

        {:error, _reason} ->
          internal_error(conn, "Failed to generate access token")
      end
    else
      {:error, :no_cookie} ->
        conn
        |> put_status(401)
        |> json(%{error: "no_refresh_token", message: "No refresh token found"})

      {:error, :token_not_found} ->
        conn
        |> delete_refresh_cookie()
        |> put_status(401)
        |> json(%{error: "invalid_refresh_token", message: "Refresh token not found"})

      {:error, :token_expired} ->
        conn
        |> delete_refresh_cookie()
        |> put_status(401)
        |> json(%{error: "token_expired", message: "Refresh token has expired"})

      {:error, :token_version_mismatch} ->
        conn
        |> delete_refresh_cookie()
        |> put_status(401)
        |> json(%{error: "token_revoked", message: "Session has been revoked"})

      {:error, :user_not_found} ->
        conn
        |> delete_refresh_cookie()
        |> put_status(401)
        |> json(%{error: "user_not_found", message: "User not found"})
    end
  end

  @doc """
  Logout the current device (delete the refresh token).
  """
  def logout(conn, _params) do
    case get_refresh_token_cookie(conn) do
      {:ok, refresh_token_id} ->
        # Try to delete the token, but don't fail if it doesn't exist
        case RefreshToken
             |> Ash.Query.filter(id == ^refresh_token_id)
             |> Ash.read_one() do
          {:ok, token} when not is_nil(token) ->
            Ash.destroy(token, actor: conn.assigns[:current_user])

          _ ->
            :ok
        end

        conn
        |> delete_refresh_cookie()
        |> json(%{message: "Logged out successfully"})

      {:error, :no_cookie} ->
        json(conn, %{message: "Already logged out"})
    end
  end

  @doc """
  Logout all devices by incrementing token_version.
  Requires authentication.
  """
  def logout_all(conn, _params) do
    user = conn.assigns.current_user

    case Ash.update(user, %{}, action: :increment_token_version, actor: user) do
      {:ok, _updated_user} ->
        # Also clear the current device's cookie
        conn
        |> delete_refresh_cookie()
        |> json(%{message: "Logged out from all devices"})

      {:error, _reason} ->
        internal_error(conn, "Failed to logout all devices")
    end
  end

  @doc """
  Get current user info. Useful for initial app load.
  """
  def me(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      user: serialize_user(user)
    })
  end

  @doc """
  Request a password reset by username (unauthenticated).

  Generates a fresh batch of single-use recovery codes and returns the plaintext
  codes in the response body exactly once. Only the Argon2 hashes are persisted.
  Because the codes are delivered in the response (this template sends no email),
  account existence is necessarily observable here.
  """
  def request_reset(conn, %{"username" => username}) do
    with {:ok, user} <- fetch_user_by_username(username),
         {:ok, updated} <- Accounts.request_password_reset(user) do
      json(conn, %{
        recovery_codes: updated.__metadata__[:plain_recovery_codes]
      })
    else
      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "user_not_found", message: "No account found for that username"})

      {:error, error} ->
        conn
        |> put_status(422)
        |> json(%{
          error: "reset_failed",
          message: "Could not generate reset codes",
          errors: format_ash_errors(error)
        })
    end
  end

  def request_reset(conn, _params) do
    ApiResponse.bad_request(conn, "Username is required")
  end

  @doc """
  Reset a password using a recovery code (unauthenticated).

  Looks up the user by username, validates and consumes the single-use code, and
  sets the new password. Expired or already-used codes are rejected.
  """
  def reset_password(conn, %{
        "username" => username,
        "recovery_code" => recovery_code,
        "new_password" => new_password
      }) do
    with {:ok, user} <- fetch_user_by_username(username),
         {:ok, _updated} <-
           Accounts.reset_password_with_recovery_code(user, recovery_code, new_password) do
      json(conn, %{message: "Password reset successfully"})
    else
      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "user_not_found", message: "No account found for that username"})

      {:error, error} ->
        ApiResponse.validation_error(conn, error, "Password reset failed")
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
    with {:ok, access_token} <- JWT.generate_access_token(user),
         {:ok, refresh_token} <- create_refresh_token(conn, user) do
      conn
      |> set_refresh_cookie(refresh_token.id)
      |> put_status(status)
      |> json(%{
        access_token: access_token,
        expires_in: JWT.access_token_lifetime(),
        user: serialize_user(user)
      })
    else
      {:error, reason} ->
        Logger.error("Failed to create tokens: #{inspect(reason)}")
        internal_error(conn, "Failed to create authentication tokens")
    end
  end

  defp create_refresh_token(conn, user) do
    device_name = get_device_name(conn)

    RefreshToken
    |> Ash.Changeset.for_create(:create, %{
      user_id: user.id,
      device_name: device_name,
      # version must equal user.token_version so the token is invalidated if
      # logout_all is called (which increments token_version).
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

  defp get_valid_refresh_token(token_id) do
    case Accounts.get_refresh_token_by_id(token_id) do
      {:ok, token} ->
        if DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt do
          {:error, :token_expired}
        else
          {:ok, token}
        end

      {:error, %Ash.Error.Query.NotFound{}} ->
        {:error, :token_not_found}

      {:error, _} ->
        {:error, :token_not_found}
    end
  end

  defp load_user_for_refresh(refresh_token) do
    case Accounts.get_user_by_id(refresh_token.user_id) do
      {:ok, user} ->
        if user.token_version == refresh_token.version do
          {:ok, user}
        else
          {:error, :token_version_mismatch}
        end

      {:error, _} ->
        {:error, :user_not_found}
    end
  end

  defp set_refresh_cookie(conn, token_id) do
    put_resp_cookie(conn, @refresh_token_cookie, token_id,
      http_only: true,
      secure: secure_cookies?(),
      same_site: "Lax",
      max_age: @refresh_token_max_age,
      path: "/"
    )
  end

  defp delete_refresh_cookie(conn) do
    delete_resp_cookie(conn, @refresh_token_cookie, path: "/")
  end

  defp secure_cookies? do
    Application.get_env(:template_app, :env) == :prod
  end

  defp internal_error(conn, message) do
    conn
    |> put_status(500)
    |> json(%{error: "internal_error", message: message})
  end
end
