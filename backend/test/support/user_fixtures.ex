defmodule TemplateApp.UserFixtures do
  @moduledoc """
  Test factories for User and related resources.

  Uses the domain's own functions as factories — no separate factory library needed.
  """

  import Ecto.Query

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.Resources.User

  @doc """
  Creates a registered user. Accepts optional attrs to override defaults.

  Example:
      create_user()
      create_user(%{username: "alice", password: "supersecret123"})
  """
  def create_user(attrs \\ %{}) do
    username = Map.get(attrs, :username, "user#{System.unique_integer([:positive])}")
    password = Map.get(attrs, :password, "password123")

    {:ok, user} = Accounts.create_user(username, password, password)
    user
  end

  @doc """
  Creates an anonymous user.
  """
  def create_anonymous do
    {:ok, user} = Accounts.create_anonymous()
    user
  end

  @doc """
  Generates a valid JWT access token for the given user.
  """
  def access_token_for(user) do
    {:ok, token} = TemplateApp.Accounts.JWT.generate_access_token(user)
    token
  end

  @doc """
  Creates a registered user with a fresh batch of recovery codes.

  Returns `{user, plain_codes}` — the reloaded user plus the one-time plaintext
  codes (only their Argon2 hashes are persisted).
  """
  def create_user_with_recovery_codes(attrs \\ %{}) do
    user = create_user(attrs)
    {:ok, updated} = Accounts.generate_recovery_codes(user, actor: user)
    {updated, updated.__metadata__.plain_recovery_codes}
  end

  @doc """
  Ages a user's recovery-code batch past its TTL so the codes count as expired.

  Drives expiry by backdating `recovery_codes_generated_at` directly via Ecto —
  the same pattern the refresh-token-expiry test uses — relative to
  `TemplateApp.Config.recovery_code_ttl_seconds/0`. Returns the reloaded user so
  callers passing it straight to an Ash action see the aged timestamp.
  """
  def expire_recovery_codes(user) do
    ttl = TemplateApp.Config.recovery_code_ttl_seconds()
    past = DateTime.add(DateTime.utc_now(), -(ttl + 60), :second)

    TemplateApp.Repo.update_all(
      from(u in User, where: u.id == ^user.id),
      set: [recovery_codes_generated_at: past]
    )

    {:ok, reloaded} = Accounts.get_user_by_id(user.id)
    reloaded
  end
end
