defmodule TemplateApp.Domains.Accounts.Checks.HasRole do
  @moduledoc """
  Policy check to verify the actor has one of the required roles.

  ## Examples

      # Require admin or superadmin role
      policy action(:admin_only_action) do
        authorize_if HasRole, role: [:admin, :superadmin]
      end

      # Require superadmin role only
      policy action(:superadmin_only_action) do
        authorize_if HasRole, role: :superadmin
      end
  """
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(opts) do
    "user has role: #{inspect(opts[:role])}"
  end

  @impl true
  def match?(_actor, %{role: role}, opts) do
    required_roles = List.wrap(opts[:role])
    role in required_roles
  end

  def match?(_actor, _context, _opts), do: false
end
