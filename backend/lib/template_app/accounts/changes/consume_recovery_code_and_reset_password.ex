defmodule TemplateApp.Accounts.Changes.ConsumeRecoveryCodeAndResetPassword do
  @moduledoc "Consumes a locked recovery code and invalidates REST sessions."

  use Ash.Resource.Change

  alias TemplateApp.Accounts

  @invalid_code_message "invalid recovery code"

  @impl true
  def change(changeset, _opts, _context) do
    code = Ash.Changeset.get_argument(changeset, :recovery_code)
    new_password = Ash.Changeset.get_argument(changeset, :new_password)
    password_hash = Argon2.hash_pwd_salt(new_password)

    Ash.Changeset.before_action(changeset, fn changeset ->
      consume_code_and_reset(changeset, code, password_hash)
    end)
  end

  defp consume_code_and_reset(changeset, code, password_hash) do
    user = changeset.data

    case remove_matching_code(user.recovery_codes || [], code) do
      {:ok, remaining} ->
        case revoke_refresh_tokens(user) do
          :ok ->
            changeset
            |> Ash.Changeset.force_change_attribute(:recovery_codes, remaining)
            |> Ash.Changeset.force_change_attribute(:hashed_password, password_hash)
            |> Ash.Changeset.force_change_attribute(:token_version, user.token_version + 1)

          {:error, _error} ->
            invalid_code(changeset)
        end

      :error ->
        invalid_code(changeset)
    end
  end

  defp remove_matching_code(codes, code) when is_binary(code) do
    {remaining, matched?} =
      Enum.reduce(codes, {[], false}, fn hash, {remaining, matched?} ->
        cond do
          matched? ->
            {[hash | remaining], true}

          Argon2.verify_pass(code, hash) ->
            {remaining, true}

          true ->
            {[hash | remaining], false}
        end
      end)

    if matched?, do: {:ok, Enum.reverse(remaining)}, else: :error
  end

  defp remove_matching_code(_codes, _code), do: :error

  defp revoke_refresh_tokens(user) do
    with {:ok, refresh_tokens} <- Accounts.get_refresh_tokens_for_user(user.id) do
      Enum.reduce_while(refresh_tokens, :ok, fn refresh_token, :ok ->
        case Ash.destroy(refresh_token, action: :revoke, actor: user) do
          :ok ->
            {:cont, :ok}

          {:ok, _destroyed} ->
            {:cont, :ok}

          {:error, error} ->
            {:halt, {:error, error}}
        end
      end)
    end
  end

  defp invalid_code(changeset) do
    Ash.Changeset.add_error(changeset,
      field: :recovery_code,
      message: @invalid_code_message
    )
  end
end
