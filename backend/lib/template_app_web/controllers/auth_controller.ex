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

  import TemplateAppWeb.Helpers.UserSerializer, only: [serialize_user: 1]

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.JWT
  alias TemplateApp.Accounts.Resources.RefreshToken
  alias TemplateAppWeb.Helpers.ApiResponse
  alias TemplateAppWeb.Plugs.RateLimitPlug

  require Ash.Query
  require Logger

  plug RateLimitPlug, [action: :login] when action in [:login]
  plug RateLimitPlug, [action: :register] when action in [:register]
  plug RateLimitPlug, [action: :request_reset] when action in [:request_reset]
  plug RateLimitPlug, [action: :reset_password] when action in [:reset_password]

  @refresh_token_cookie "_template_app_refresh"
  @refresh_token_max_age 7 * 24 * 60 * 60

  def login(conn, %{"username" => username, "password" => password}) do
    case Accounts.sign_in(username, password) do
      {:ok, user} ->
        create_tokens_and_respond(conn, user)

      {:error, _reason} ->
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
         {:ok, refresh_token} <- get_valid_refresh_token(refresh_token_id),
         {:ok, user} <- load_user_for_refresh(refresh_token),
         {:ok, access_token} <- JWT.generate_access_token(user),
         {:ok, new_refresh_token} <- rotate_refresh_token(refresh_token, user) do
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

      {:error, _reason} ->
        ApiResponse.internal_error(conn, "Failed to refresh session")
    end
  end

  def logout(conn, _params) do
    case get_refresh_token_cookie(conn) do
      {:ok, refresh_token_id} ->
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
        |> ApiResponse.message("Logged out successfully")

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

  def request_reset(conn, %{"username" => username}) do
    case fetch_user_by_username(username) do
      {:ok, user} ->
        case Accounts.request_password_reset(user) do
          {:ok, updated} ->
            ApiResponse.success(conn, %{
              recovery_codes: updated.__metadata__[:plain_recovery_codes]
            })

          {:error, error} ->
            ApiResponse.validation_error(conn, error, "Could not generate reset codes")
        end

      {:error, :not_found} ->
        ApiResponse.success(conn, %{recovery_codes: fake_recovery_codes()})
    end
  end

  def request_reset(conn, _params) do
    ApiResponse.bad_request(conn, "Username is required")
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

          {:error, error} ->
            ApiResponse.validation_error(conn, error, "Password reset failed")
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
      {:error, reason} ->
        Logger.error("Failed to create tokens: #{inspect(reason)}")
        ApiResponse.internal_error(conn, "Failed to create authentication tokens")
    end
  end

  defp rotate_refresh_token(old_token, user) do
    Ash.destroy(old_token, authorize?: false)

    RefreshToken
    |> Ash.Changeset.for_create(:create, %{
      user_id: user.id,
      device_name: old_token.device_name,
      version: user.token_version
    })
    |> Ash.create()
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

  defp fake_recovery_codes do
    count = TemplateApp.Config.recovery_code_count()

    for _ <- 1..count do
      8
      |> :crypto.strong_rand_bytes()
      |> Base.encode32(padding: false)
      |> binary_part(0, 10)
      |> String.upcase()
    end
  end

  defp secure_cookies? do
    Application.get_env(:template_app, :env) == :prod
  end
end
