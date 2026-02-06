defmodule TemplateAppWeb.Serializers.UserSerializerTest do
  @moduledoc """
  Tests for the UserSerializer module.
  """

  use TemplateApp.DataCase, async: true

  alias TemplateApp.Domains.Accounts
  alias TemplateAppWeb.Serializers.UserSerializer

  describe "serialize/1" do
    test "returns nil for nil input" do
      assert UserSerializer.serialize(nil) == nil
    end

    test "serializes a registered user with all fields" do
      {:ok, user} = Accounts.create_user("serializeuser", "password123", "password123", nil)

      result = UserSerializer.serialize(user)

      assert result.id == user.id
      assert result.username == user.username
      assert result.is_anonymous == false
      assert result.has_recovery_codes == false
      assert result.recovery_codes_count == 0

      refute Map.has_key?(result, :hashed_password)
      refute Map.has_key?(result, :recovery_codes)
    end

    test "includes recovery codes count after generation" do
      {:ok, user} = Accounts.create_user("withcodes", "password123", "password123", nil)
      {:ok, user} = Accounts.generate_recovery_codes(user, actor: user)

      result = UserSerializer.serialize(user)

      assert result.has_recovery_codes == true
      assert result.recovery_codes_count > 0
    end

    test "serializes anonymous user" do
      {:ok, user} = Accounts.create_anonymous()

      result = UserSerializer.serialize(user)

      assert result.is_anonymous == true
      assert result.id == user.id
    end
  end
end
