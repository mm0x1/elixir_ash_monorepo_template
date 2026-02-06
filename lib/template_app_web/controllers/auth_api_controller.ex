defmodule TemplateAppWeb.AuthApiController do
  @moduledoc """
  API controller for authentication endpoints.
  """

  use TemplateAppWeb, :controller

  alias TemplateAppWeb.Serializers.UserSerializer
  alias TemplateApp.Domains.Accounts
  alias TemplateAppWeb.Helpers.ErrorFormatter

  @doc """
  Register a new user with password.
  """
  def register(conn, params) do
    case Accounts.create_user(
           params["username"],
           params["password"],
           params["password_confirmation"]
         ) do
      {:ok, user} ->
        conn
        |> AshAuthentication.Plug.Helpers.store_in_session(user)
        |> json(%{
          success: true,
          data: %{user: UserSerializer.serialize(user)}
        })

      {:error, error} ->
        {status, formatted_errors} = ErrorFormatter.format_error_with_status(error)

        conn
        |> put_status(status)
        |> json(%{success: false, errors: formatted_errors})
    end
  end

  @doc """
  Sign in with username and password.
  """
  def sign_in(conn, params) do
    case Accounts.sign_in(params["username"], params["password"]) do
      {:ok, user} ->
        conn
        |> AshAuthentication.Plug.Helpers.store_in_session(user)
        |> json(%{
          success: true,
          data: %{user: UserSerializer.serialize(user)}
        })

      {:error, error} ->
        {status, formatted_errors} = ErrorFormatter.format_error_with_status(error)

        conn
        |> put_status(status)
        |> json(%{success: false, errors: formatted_errors})
    end
  end

  @doc """
  Sign out - clear session.
  """
  def sign_out(conn, _params) do
    conn
    |> Plug.Conn.clear_session()
    |> json(%{success: true})
  end

  @doc """
  Create an anonymous user session.
  """
  def create_anonymous(conn, _params) do
    case Accounts.create_anonymous() do
      {:ok, user} ->
        # Generate a token for the anonymous user
        {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
        user = %{user | __metadata__: Map.put(user.__metadata__, :token, token)}

        conn
        |> AshAuthentication.Plug.Helpers.store_in_session(user)
        |> json(%{
          success: true,
          data: %{user: UserSerializer.serialize(user)}
        })

      {:error, error} ->
        {status, formatted_errors} = ErrorFormatter.format_error_with_status(error)

        conn
        |> put_status(status)
        |> json(%{success: false, errors: formatted_errors})
    end
  end

  @doc """
  Generate recovery codes for the authenticated user.
  """
  def generate_recovery_codes(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.generate_recovery_codes(user, actor: user) do
      {:ok, updated} ->
        codes = updated.__metadata__.plain_recovery_codes

        json(conn, %{
          success: true,
          data: %{
            recovery_codes: codes,
            message: "Save these codes. They will not be shown again."
          }
        })

      {:error, error} ->
        {status, formatted_errors} = ErrorFormatter.format_error_with_status(error)

        conn
        |> put_status(status)
        |> json(%{success: false, errors: formatted_errors})
    end
  end

  @doc """
  Reset password using a recovery code.
  """
  def reset_password(conn, %{
        "username" => username,
        "recovery_code" => code,
        "new_password" => pw
      }) do
    with {:ok, user} <- Accounts.get_by_username(username),
         {:ok, _} <- Accounts.reset_password_with_recovery_code(user, code, pw) do
      json(conn, %{
        success: true,
        data: %{message: "Password reset successful"}
      })
    else
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, errors: %{base: ["Invalid credentials"]}})
    end
  end

  def reset_password(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{success: false, errors: %{base: ["Missing required parameters"]}})
  end

  @doc """
  Convert an anonymous user to a registered user.
  """
  def convert_to_registered(conn, %{
        "username" => username,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    user = conn.assigns.current_user

    case Accounts.convert_to_registered(user, username, password, password_confirmation,
           actor: user
         ) do
      {:ok, updated} ->
        # Generate a token for the converted user
        {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(updated)
        updated = %{updated | __metadata__: Map.put(updated.__metadata__, :token, token)}

        conn
        |> AshAuthentication.Plug.Helpers.store_in_session(updated)
        |> json(%{
          success: true,
          data: %{user: UserSerializer.serialize(updated)}
        })

      {:error, error} ->
        {status, formatted_errors} = ErrorFormatter.format_error_with_status(error)

        conn
        |> put_status(status)
        |> json(%{success: false, errors: formatted_errors})
    end
  end

  def convert_to_registered(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{success: false, errors: %{base: ["Missing required parameters"]}})
  end
end
