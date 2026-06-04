defmodule TemplateAppWeb.AccountController do
  @moduledoc """
  Authenticated account self-service endpoints.

  Re-expresses the former RPC user operations as plain REST endpoints behind the
  token-auth pipeline:

  - `PATCH /account/username`        — change the current user's username
  - `POST  /account/recovery-codes`  — (re)generate the current user's recovery codes
  - `POST  /account/convert`         — convert an anonymous user into a registered one

  All actions run with `actor: conn.assigns.current_user` so the deny-by-default
  Ash policies (gated on `id == ^actor(:id)`) authorize them.
  """

  use TemplateAppWeb, :controller

  import TemplateAppWeb.Helpers.UserSerializer, only: [serialize_user: 1]

  alias TemplateApp.Accounts
  alias TemplateAppWeb.Helpers.ApiResponse

  @doc """
  Change the current user's username.
  """
  def update_username(conn, %{"username" => username}) do
    user = conn.assigns.current_user

    case Accounts.change_username(user, username, actor: user) do
      {:ok, updated} ->
        json(conn, %{user: serialize_user(updated)})

      {:error, error} ->
        respond_error(conn, error)
    end
  end

  def update_username(conn, _params) do
    bad_request(conn, "Username is required")
  end

  @doc """
  Generate a fresh batch of recovery codes for the current user.

  The plaintext codes are returned once; only their Argon2 hashes are persisted.
  """
  def generate_recovery_codes(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.generate_recovery_codes(user, actor: user) do
      {:ok, updated} ->
        json(conn, %{
          user: serialize_user(updated),
          recovery_codes: updated.__metadata__[:plain_recovery_codes]
        })

      {:error, error} ->
        respond_error(conn, error)
    end
  end

  @doc """
  Convert an anonymous user into a registered one with a username and password.
  """
  def convert(conn, %{
        "username" => username,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    user = conn.assigns.current_user

    case Accounts.convert_to_registered(user, username, password, password_confirmation,
           actor: user
         ) do
      {:ok, updated} ->
        json(conn, %{user: serialize_user(updated)})

      {:error, error} ->
        respond_error(conn, error)
    end
  end

  def convert(conn, _params) do
    bad_request(conn, "Username, password, and password_confirmation are required")
  end

  # Private helpers

  defp respond_error(conn, %Ash.Error.Forbidden{} = error), do: ApiResponse.forbidden(conn, error)

  defp respond_error(conn, error),
    do: ApiResponse.validation_error(conn, error, "Request failed")

  defp bad_request(conn, message), do: ApiResponse.bad_request(conn, message)
end
