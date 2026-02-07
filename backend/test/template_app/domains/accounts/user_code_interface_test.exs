defmodule TemplateApp.Domains.Accounts.UserCodeInterfaceTest do
  @moduledoc """
  Tests for the User resource code interface.
  """

  use TemplateApp.DataCase, async: true

  alias TemplateApp.Domains.Accounts

  describe "create_user/4" do
    test "creates a user with valid inputs" do
      assert {:ok, user} = Accounts.create_user("testuser", "password123", "password123", nil)

      assert to_string(user.username) == "testuser"
      assert user.hashed_password != nil
      assert user.id != nil
    end

    test "returns metadata with token from action" do
      assert {:ok, user} = Accounts.create_user("metauser", "password123", "password123", nil)

      assert user.__metadata__ != nil
      assert user.__metadata__.token != nil
    end

    test "fails when password is too short" do
      assert {:error, error} = Accounts.create_user("testuser", "short", "short", nil)

      assert %Ash.Error.Invalid{} = error
    end

    test "fails when passwords do not match" do
      assert {:error, error} = Accounts.create_user("testuser", "password123", "different", nil)

      assert %Ash.Error.Invalid{} = error
    end

    test "fails when username already exists" do
      assert {:ok, _user} = Accounts.create_user("duplicate", "password123", "password123", nil)

      assert {:error, _error} =
               Accounts.create_user("duplicate", "password123", "password123", nil)
    end
  end
end
