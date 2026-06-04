defmodule TemplateAppWeb.Helpers.UserSerializer do
  @moduledoc """
  Shared JSON shaping for the auth/account REST controllers.

  Provides the canonical user JSON representation and the validation-error
  shape used by both `AuthController` and `AccountController`, so the two
  controllers stay in sync.
  """

  @doc """
  Serialize a `User` into the canonical JSON map returned by the API.

  Loads the recovery-code calculations (with authorization bypassed, since the
  caller has already been authenticated/authorized at the controller boundary).
  """
  def serialize_user(user) do
    {:ok, user} = Ash.load(user, [:has_recovery_codes, :recovery_codes_count], authorize?: false)

    %{
      id: user.id,
      username: to_string(user.username),
      is_anonymous: user.is_anonymous,
      role: user.role,
      has_recovery_codes: user.has_recovery_codes,
      recovery_codes_count: user.recovery_codes_count
    }
  end

  @doc """
  Format an Ash error into a `[%{field:, message:}]` list for JSON responses.
  """
  def format_ash_errors(%Ash.Error.Invalid{errors: errors}) do
    Enum.map(errors, fn error ->
      %{
        field: Map.get(error, :field),
        message: Exception.message(error)
      }
    end)
  end

  def format_ash_errors(error) do
    [%{field: nil, message: Exception.message(error)}]
  end
end
