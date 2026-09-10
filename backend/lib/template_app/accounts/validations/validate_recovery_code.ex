defmodule TemplateApp.Accounts.Validations.ValidateRecoveryCode do
  @moduledoc "Validates recovery code against stored hashes."

  use Ash.Resource.Validation

  @invalid_code_message "invalid recovery code"

  @impl true
  def validate(changeset, _opts, _ctx) do
    code = Ash.Changeset.get_argument(changeset, :recovery_code)
    user = changeset.data

    if valid_code?(user, code) do
      :ok
    else
      {:error, field: :recovery_code, message: @invalid_code_message}
    end
  end

  defp valid_code?(%{is_anonymous: true}, _code), do: false

  defp valid_code?(_user, code) when not is_binary(code), do: false

  defp valid_code?(%{recovery_codes: recovery_codes}, _code)
       when recovery_codes in [nil, []],
       do: false

  defp valid_code?(%{recovery_codes_generated_at: nil}, _code), do: false

  defp valid_code?(user, code) do
    not expired?(user.recovery_codes_generated_at) and
      Enum.any?(user.recovery_codes, &Argon2.verify_pass(code, &1))
  end

  defp expired?(%DateTime{} = generated_at) do
    ttl = TemplateApp.Config.recovery_code_ttl_seconds()
    DateTime.diff(DateTime.utc_now(), generated_at, :second) > ttl
  end
end
