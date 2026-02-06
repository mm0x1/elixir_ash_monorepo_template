defmodule TemplateApp.Domains.Accounts.Validations.ValidateRecoveryCode do
  @moduledoc "Validates recovery code against stored hashes."

  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _ctx) do
    code = Ash.Changeset.get_argument(changeset, :recovery_code)
    user = changeset.data

    cond do
      user.is_anonymous ->
        {:error, field: :recovery_code, message: "anonymous users cannot reset password"}

      Enum.empty?(user.recovery_codes || []) ->
        {:error, field: :recovery_code, message: "no recovery codes configured"}

      not Enum.any?(user.recovery_codes, &Argon2.verify_pass(code, &1)) ->
        {:error, field: :recovery_code, message: "invalid recovery code"}

      true ->
        :ok
    end
  end
end
