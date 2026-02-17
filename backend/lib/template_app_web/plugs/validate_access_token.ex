defmodule TemplateAppWeb.Plugs.ValidateAccessToken do
  @moduledoc """
  Plug that validates JWT access tokens from the Authorization header.

  Extracts the Bearer token, verifies the JWT signature, loads the full user,
  and assigns it to `conn.assigns.current_user`.

  This is critical for ash_typescript's RPC, which reads `conn.assigns.current_user`
  as the actor for authorization.

  On failure, returns a 401 JSON response.
  """

  import Plug.Conn
  alias TemplateApp.Auth.JWT
  alias TemplateApp.Domains.Accounts

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- extract_bearer_token(conn),
         {:ok, claims} <- JWT.verify_access_token(token),
         {:ok, user} <- load_and_validate_user(claims) do
      conn
      |> assign(:current_user, user)
      |> Ash.PlugHelpers.set_actor(user)
    else
      {:error, :no_token} ->
        unauthorized(conn, "No authorization token provided")

      {:error, :invalid_token} ->
        unauthorized(conn, "Invalid or expired token")

      {:error, :user_not_found} ->
        unauthorized(conn, "User not found")

      {:error, :token_version_mismatch} ->
        unauthorized(conn, "Token has been revoked")

      {:error, reason} ->
        Logger.warning("Access token validation failed: #{inspect(reason)}")
        unauthorized(conn, "Authentication failed")
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, :no_token}
    end
  end

  defp load_and_validate_user(%{"sub" => user_id, "token_version" => token_version}) do
    case Accounts.get_user_by_id(user_id) do
      {:ok, user} ->
        if user.token_version == token_version do
          {:ok, user}
        else
          {:error, :token_version_mismatch}
        end

      {:error, %Ash.Error.Query.NotFound{}} ->
        {:error, :user_not_found}

      {:error, _reason} ->
        {:error, :user_not_found}
    end
  end

  defp load_and_validate_user(_claims), do: {:error, :invalid_token}

  defp unauthorized(conn, message) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.json(%{
      error: "unauthorized",
      message: message
    })
    |> halt()
  end
end
