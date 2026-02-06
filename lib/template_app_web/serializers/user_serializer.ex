defmodule TemplateAppWeb.Serializers.UserSerializer do
  @moduledoc """
  Serializes User resources into plain maps for JSON responses.
  """

  alias TemplateApp.Domains.Accounts.Resources.User

  @doc """
  Serializes a User struct to a plain map.

  ## Examples

      iex> serialize(%User{id: "123", username: "john", is_anonymous: false, role: :user})
      %{id: "123", username: "john", is_anonymous: false, role: "user", ...}

      iex> serialize(nil)
      nil

      iex> serialize([user1, user2])
      [%{id: ..., ...}, %{id: ..., ...}]
  """
  def serialize(nil), do: nil

  def serialize(users) when is_list(users) do
    Enum.map(users, &serialize/1)
  end

  def serialize(%User{} = user) do
    %{
      id: user.id,
      username: user.username,
      is_anonymous: user.is_anonymous,
      role: to_string(user.role),
      has_recovery_codes: has_recovery_codes?(user),
      recovery_codes_count: recovery_codes_count(user)
    }
  end

  defp has_recovery_codes?(%User{recovery_codes: [_ | _]}), do: true
  defp has_recovery_codes?(_), do: false

  defp recovery_codes_count(%User{recovery_codes: codes}) when is_list(codes), do: length(codes)
  defp recovery_codes_count(_), do: 0
end
