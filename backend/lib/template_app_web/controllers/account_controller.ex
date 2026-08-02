defmodule TemplateAppWeb.AccountController do
  @moduledoc """
  Authenticated account self-service endpoints.

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

  def update_username(conn, %{"username" => username}) do
    user = conn.assigns.current_user

    case Accounts.change_username(user, username, actor: user) do
      {:ok, updated} ->
        {:ok, updated} =
          Ash.load(updated, [:has_recovery_codes, :recovery_codes_count], authorize?: false)

        ApiResponse.success(conn, %{user: serialize_user(updated)})

      {:error, error} ->
        respond_error(conn, error)
    end
  end

  def update_username(conn, _params) do
    ApiResponse.bad_request(conn, "Username is required")
  end

  def generate_recovery_codes(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.generate_recovery_codes(user, actor: user) do
      {:ok, updated} ->
        {:ok, updated} =
          Ash.load(updated, [:has_recovery_codes, :recovery_codes_count], authorize?: false)

        ApiResponse.success(conn, %{
          user: serialize_user(updated),
          recovery_codes: updated.__metadata__[:plain_recovery_codes]
        })

      {:error, error} ->
        respond_error(conn, error)
    end
  end

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
        {:ok, updated} =
          Ash.load(updated, [:has_recovery_codes, :recovery_codes_count], authorize?: false)

        ApiResponse.success(conn, %{user: serialize_user(updated)})

      {:error, error} ->
        respond_error(conn, error)
    end
  end

  def convert(conn, _params) do
    ApiResponse.bad_request(conn, "Username, password, and password_confirmation are required")
  end

  # Private helpers

  defp respond_error(conn, %Ash.Error.Forbidden{} = error), do: ApiResponse.forbidden(conn, error)

  defp respond_error(conn, error),
    do: ApiResponse.validation_error(conn, error, "Request failed")
end
