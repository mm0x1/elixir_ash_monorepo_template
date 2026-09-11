defmodule TemplateApp.Repo.Migrations.EnforceAuthenticationConstraints do
  @moduledoc """
  Enforces authentication invariants that must survive direct SQL writes.

  Existing data is validated by the migration before these constraints are
  created.
  """

  use Ecto.Migration

  def up do
    create(
      constraint(:refresh_tokens, :refresh_tokens_version_positive,
        check: """
          version > 0
        """
      )
    )

    create(
      constraint(:refresh_tokens, :refresh_tokens_secret_hash_length,
        check: """
          octet_length(secret_hash) = 32
        """
      )
    )

    create(
      constraint(:users, :users_role_is_valid,
        check: """
          role IN ('user', 'admin', 'superadmin')
        """
      )
    )

    create(
      constraint(:users, :users_token_version_positive,
        check: """
          token_version > 0
        """
      )
    )
  end

  def down do
    drop_if_exists(constraint(:users, :users_token_version_positive))

    drop_if_exists(constraint(:users, :users_role_is_valid))

    drop_if_exists(constraint(:refresh_tokens, :refresh_tokens_secret_hash_length))

    drop_if_exists(constraint(:refresh_tokens, :refresh_tokens_version_positive))
  end
end
