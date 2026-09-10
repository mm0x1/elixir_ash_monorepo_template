defmodule TemplateApp.Accounts.ValidateRecoveryCodeTest do
  @moduledoc """
  Focused coverage of the recovery-code TTL rule at the Ash layer.

  Single-use and wrong-code rejection are already covered in UserActionsTest;
  this expresses the *expiry* rule directly: a code that is otherwise valid is
  rejected once its batch ages past `recovery_code_ttl_seconds/0`.
  """

  use TemplateApp.DataCase, async: true

  import TemplateApp.UserFixtures

  alias TemplateApp.Accounts

  test "rejects an otherwise-valid code once the batch has expired" do
    {user, [code | _]} = create_user_with_recovery_codes()

    # Sanity: the code is valid before expiry.
    assert {:ok, _} =
             Accounts.reset_password_with_recovery_code(user, code, "freshpassword123")

    {user, [code | _]} = create_user_with_recovery_codes()
    user = expire_recovery_codes(user)

    assert {:error, %Ash.Error.Invalid{} = error} =
             Accounts.reset_password_with_recovery_code(user, code, "newpassword123")

    assert Exception.message(error) =~ "invalid recovery code"
  end
end
