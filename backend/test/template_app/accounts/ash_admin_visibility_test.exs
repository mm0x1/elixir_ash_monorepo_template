defmodule TemplateApp.Accounts.AshAdminVisibilityTest do
  use ExUnit.Case, async: true

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.Resources.{RefreshToken, Token, User}

  test "AshAdmin exposes only the read-only user resource" do
    assert AshAdmin.Domain.show?(Accounts)
    assert AshAdmin.Domain.show_resources(Accounts) == [User]

    assert AshAdmin.Resource.read_actions(User) == [:read]
    assert AshAdmin.Resource.generic_actions(User) == []
    assert AshAdmin.Resource.create_actions(User) == []
    assert AshAdmin.Resource.update_actions(User) == []
    assert AshAdmin.Resource.destroy_actions(User) == []
  end

  test "token and refresh-token resources expose no admin actions" do
    for resource <- [Token, RefreshToken] do
      assert AshAdmin.Resource.read_actions(resource) == []
      assert AshAdmin.Resource.generic_actions(resource) == []
      assert AshAdmin.Resource.create_actions(resource) == []
      assert AshAdmin.Resource.update_actions(resource) == []
      assert AshAdmin.Resource.destroy_actions(resource) == []
    end
  end

  test "refresh bearer digests are not public resource attributes" do
    assert Ash.Resource.Info.public_attribute(RefreshToken, :secret_hash) == nil
    assert Ash.Resource.Info.attribute(RefreshToken, :secret_hash).sensitive?
  end
end
