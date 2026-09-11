defmodule TemplateApp.Accounts.DatabaseConstraintsTest do
  use TemplateApp.DataCase, async: false

  import Ecto.Query
  import TemplateApp.UserFixtures

  alias TemplateApp.Accounts.RefreshSessions
  alias TemplateApp.Accounts.Resources.{RefreshToken, User}

  test "direct SQL rejects invalid roles" do
    user = create_user()

    assert_raise Postgrex.Error, fn ->
      Repo.query!("UPDATE users SET role = 'operator' WHERE id = $1", [Ecto.UUID.dump!(user.id)])
    end
  end

  test "direct SQL rejects non-positive user token versions" do
    user = create_user()

    assert_raise Postgrex.Error, fn ->
      Repo.query!("UPDATE users SET token_version = 0 WHERE id = $1", [Ecto.UUID.dump!(user.id)])
    end
  end

  test "direct SQL rejects non-positive refresh versions" do
    user = create_user()
    {:ok, refresh_secret} = RefreshSessions.issue(user, "constraint-test")
    secret_hash = :crypto.hash(:sha256, refresh_secret)

    refresh_token =
      Repo.one!(from(token in RefreshToken, where: token.secret_hash == ^secret_hash))

    assert_raise Postgrex.Error, fn ->
      Repo.query!("UPDATE refresh_tokens SET version = 0 WHERE id = $1", [
        Ecto.UUID.dump!(refresh_token.id)
      ])
    end
  end

  test "direct SQL rejects refresh digests with the wrong length" do
    user = create_user()
    {:ok, refresh_secret} = RefreshSessions.issue(user, "constraint-test")
    secret_hash = :crypto.hash(:sha256, refresh_secret)

    refresh_token =
      Repo.one!(from(token in RefreshToken, where: token.secret_hash == ^secret_hash))

    assert_raise Postgrex.Error, fn ->
      Repo.query!("UPDATE refresh_tokens SET secret_hash = $1 WHERE id = $2", [
        <<1, 2, 3>>,
        Ecto.UUID.dump!(refresh_token.id)
      ])
    end
  end

  test "the resource constraints are declared for current database fields" do
    assert Enum.map(AshPostgres.DataLayer.Info.check_constraints(User), & &1.name) == [
             "users_role_is_valid",
             "users_token_version_positive"
           ]

    assert Enum.map(AshPostgres.DataLayer.Info.check_constraints(RefreshToken), & &1.name) == [
             "refresh_tokens_version_positive",
             "refresh_tokens_secret_hash_length"
           ]
  end
end
