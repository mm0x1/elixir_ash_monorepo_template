defmodule TemplateApp.Repo.Migrations.HashRefreshSecrets do
  @moduledoc """
  Replaces refresh-token IDs in cookies with random bearer secrets.

  Existing refresh sessions are intentionally invalidated before the digest
  column becomes required. Clients must sign in again after this migration;
  there is no legacy ID or dual-format lookup path.
  """

  use Ecto.Migration

  def up do
    execute("DELETE FROM refresh_tokens")

    alter table(:refresh_tokens) do
      add(:secret_hash, :binary, null: false)
    end

    create(
      unique_index(:refresh_tokens, [:secret_hash],
        name: "refresh_tokens_unique_secret_hash_index"
      )
    )
  end

  def down do
    drop_if_exists(
      unique_index(:refresh_tokens, [:secret_hash],
        name: "refresh_tokens_unique_secret_hash_index"
      )
    )

    alter table(:refresh_tokens) do
      remove(:secret_hash)
    end
  end
end
