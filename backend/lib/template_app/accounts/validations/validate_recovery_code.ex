defmodule TemplateApp.Accounts.Validations.ValidateRecoveryCode do
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

      expired?(user.recovery_codes_generated_at) ->
        {:error, field: :recovery_code, message: "recovery codes have expired"}

      not Enum.any?(user.recovery_codes, &Argon2.verify_pass(code, &1)) ->
        {:error, field: :recovery_code, message: "invalid recovery code"}

      true ->
        :ok
    end
  end

  # A nil timestamp means we cannot establish freshness, so treat the batch as
  # expired. Otherwise the batch is valid for recovery_code_ttl_seconds.
  defp expired?(nil), do: true

  defp expired?(%DateTime{} = generated_at) do
    ttl = TemplateApp.Config.recovery_code_ttl_seconds()
    DateTime.diff(DateTime.utc_now(), generated_at, :second) > ttl
  end
end
