defmodule TemplateApp.Accounts.RefreshSessions do
  @moduledoc "Atomic operations for custom REST refresh sessions."

  alias TemplateApp.Accounts.JWT
  alias TemplateApp.Accounts.Resources.{RefreshToken, User}

  @doc "Atomically consumes a refresh token and creates its replacement."
  def rotate(token_id) do
    transact(fn -> rotate_in_transaction(token_id) end)
  end

  @doc "Revokes the refresh session identified by a cookie value."
  def revoke(token_id) do
    transact(fn -> revoke_in_transaction(token_id) end)
  end

  defp rotate_in_transaction(token_id) do
    with {:ok, refresh_token} <- locked_refresh_token(token_id),
         :ok <- not_expired(refresh_token),
         {:ok, user} <- locked_user(refresh_token.user_id),
         :ok <- matching_version(user, refresh_token),
         {:ok, access_token} <- JWT.generate_access_token(user),
         :ok <- consume(refresh_token, user) do
      case create_replacement(refresh_token, user) do
        {:ok, replacement} ->
          %{access_token: access_token, refresh_token: replacement}

        {:error, _error} ->
          Ash.DataLayer.rollback(RefreshToken, {:session_error, :rotation_failed})
      end
    else
      {:error, reason} -> {:session_error, reason}
    end
  end

  defp revoke_in_transaction(token_id) do
    with {:ok, refresh_token} <- locked_refresh_token(token_id),
         {:ok, user} <- locked_user(refresh_token.user_id) do
      case consume(refresh_token, user) do
        :ok -> {:session_result, :revoked}
        {:error, _error} -> {:session_error, :logout_failed}
      end
    else
      {:error, _reason} -> {:session_result, :already_logged_out}
    end
  end

  defp locked_refresh_token(token_id) do
    case Ash.get(RefreshToken, token_id, lock: :for_update) do
      {:ok, nil} -> {:error, :token_not_found}
      {:ok, refresh_token} -> {:ok, refresh_token}
      {:error, _error} -> {:error, :token_not_found}
    end
  end

  defp locked_user(user_id) do
    case Ash.get(User, user_id, lock: :for_update) do
      {:ok, nil} -> {:error, :user_not_found}
      {:ok, user} -> {:ok, user}
      {:error, _error} -> {:error, :user_not_found}
    end
  end

  defp not_expired(%{expires_at: expires_at}) do
    if DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
      {:error, :token_expired}
    else
      :ok
    end
  end

  defp matching_version(user, refresh_token) do
    if user.token_version == refresh_token.version do
      :ok
    else
      {:error, :token_version_mismatch}
    end
  end

  defp consume(refresh_token, user) do
    case Ash.destroy(refresh_token, action: :revoke, actor: user) do
      :ok -> :ok
      {:ok, _destroyed} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp create_replacement(refresh_token, user) do
    RefreshToken
    |> Ash.Changeset.for_create(:create, %{
      user_id: user.id,
      device_name: refresh_token.device_name,
      version: user.token_version
    })
    |> Ash.create(actor: user)
  end

  defp transact(fun) do
    case Ash.transact([RefreshToken, User], fun) do
      {:ok, {:session_result, result}} ->
        {:ok, result}

      {:ok, {:session_error, reason}} ->
        {:error, reason}

      {:ok, result} ->
        {:ok, result}

      {:error, error} ->
        {:error, normalize_error(error)}
    end
  end

  defp normalize_error(%Ash.Error.Unknown.UnknownError{value: [session_error: reason]}),
    do: reason

  defp normalize_error(_error), do: :session_operation_failed
end
