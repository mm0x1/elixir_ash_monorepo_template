defmodule TemplateApp.Accounts.RefreshSessions do
  @moduledoc "Atomic operations for custom REST refresh sessions."

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.JWT
  alias TemplateApp.Accounts.Resources.{RefreshToken, User}

  @doc "Issues a refresh session and returns its raw cookie secret."
  def issue(user, device_name) do
    with {:ok, refresh_token} <-
           Accounts.create_refresh_session(user.id, device_name, user.token_version, actor: user) do
      issued_secret(refresh_token)
    end
  end

  @doc "Atomically consumes a refresh token and creates its replacement."
  def rotate(refresh_secret) do
    transact(fn -> rotate_in_transaction(refresh_secret) end)
  end

  @doc "Revokes the refresh session identified by a cookie value."
  def revoke(refresh_secret) do
    transact(fn -> revoke_in_transaction(refresh_secret) end)
  end

  defp rotate_in_transaction(refresh_secret) do
    with {:ok, refresh_token} <- locked_refresh_token(refresh_secret),
         :ok <- not_expired(refresh_token),
         {:ok, user} <- locked_user(refresh_token.user_id),
         :ok <- matching_version(user, refresh_token),
         {:ok, access_token} <- JWT.generate_access_token(user),
         :ok <- consume(refresh_token, user) do
      case create_replacement(refresh_token, user) do
        {:ok, replacement} ->
          case issued_secret(replacement) do
            {:ok, replacement_secret} ->
              %{access_token: access_token, refresh_secret: replacement_secret}

            {:error, _reason} ->
              Ash.DataLayer.rollback(RefreshToken, {:session_error, :rotation_failed})
          end

        {:error, _error} ->
          Ash.DataLayer.rollback(RefreshToken, {:session_error, :rotation_failed})
      end
    else
      {:error, reason} -> {:session_error, reason}
    end
  end

  defp revoke_in_transaction(refresh_secret) do
    with {:ok, refresh_token} <- locked_refresh_token(refresh_secret),
         {:ok, user} <- locked_user(refresh_token.user_id) do
      case consume(refresh_token, user) do
        :ok -> {:session_result, :revoked}
        {:error, _error} -> {:session_error, :logout_failed}
      end
    else
      {:error, _reason} -> {:session_result, :already_logged_out}
    end
  end

  defp locked_refresh_token(refresh_secret) when is_binary(refresh_secret) do
    query =
      RefreshToken
      |> Ash.Query.for_read(:by_secret_hash, %{secret_hash: hash_secret(refresh_secret)})
      |> Ash.Query.lock(:for_update)

    case Ash.read_one(query) do
      {:ok, nil} -> {:error, :token_not_found}
      {:ok, refresh_token} -> {:ok, refresh_token}
      {:error, _error} -> {:error, :token_not_found}
    end
  end

  defp locked_refresh_token(_refresh_secret), do: {:error, :token_not_found}

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
    Accounts.create_refresh_session(
      user.id,
      refresh_token.device_name,
      user.token_version,
      actor: user
    )
  end

  defp issued_secret(%{__metadata__: %{plain_refresh_secret: refresh_secret}})
       when is_binary(refresh_secret),
       do: {:ok, refresh_secret}

  defp issued_secret(_refresh_token), do: {:error, :session_creation_failed}

  defp hash_secret(refresh_secret), do: :crypto.hash(:sha256, refresh_secret)

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
