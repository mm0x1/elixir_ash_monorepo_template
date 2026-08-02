defmodule TemplateAppWeb.Helpers.UserSerializer do
  @moduledoc """
  Pure JSON shaping for the User resource.

  Maps a fully-loaded `User` struct into the canonical API representation.
  The caller is responsible for loading any computed fields (e.g.
  `:has_recovery_codes`, `:recovery_codes_count`) before calling this.
  """

  def serialize_user(user) do
    %{
      id: user.id,
      username: to_string(user.username),
      is_anonymous: user.is_anonymous,
      role: user.role,
      has_recovery_codes: user.has_recovery_codes,
      recovery_codes_count: user.recovery_codes_count
    }
  end
end
