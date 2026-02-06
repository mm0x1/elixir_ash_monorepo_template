defmodule TemplateApp.Domains.Accounts.Changes.ConsumeRecoveryCodeAndResetPassword do
  @moduledoc "Removes used recovery code and sets new password."

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _ctx) do
    code = Ash.Changeset.get_argument(changeset, :recovery_code)
    new_password = Ash.Changeset.get_argument(changeset, :new_password)
    current_codes = changeset.data.recovery_codes

    remaining = Enum.reject(current_codes, &Argon2.verify_pass(code, &1))

    changeset
    |> Ash.Changeset.change_attribute(:recovery_codes, remaining)
    |> Ash.Changeset.change_attribute(:hashed_password, Argon2.hash_pwd_salt(new_password))
  end
end
