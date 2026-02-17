defmodule TemplateApp.Domains.Accounts.UserActionsTest do
  @moduledoc """
  Tests for non-trivial User resource actions.

  Covers the business rules that the product promises to users and that
  would not be caught by reading the code alone.
  """

  use TemplateApp.DataCase, async: true

  import TemplateApp.UserFixtures

  alias TemplateApp.Domains.Accounts

  # ---------------------------------------------------------------------------
  # create_user (register_with_password)
  # ---------------------------------------------------------------------------

  describe "create_user/3" do
    test "creates a user with hashed password" do
      {:ok, user} = Accounts.create_user("validuser", "password123", "password123")

      assert to_string(user.username) == "validuser"
      assert user.id != nil
      assert user.hashed_password != "password123"
    end

    test "fails when username already exists" do
      {:ok, _} = Accounts.create_user("duplicate", "password123", "password123")

      assert {:error, _} = Accounts.create_user("duplicate", "password123", "password123")
    end

    test "fails when password is shorter than 8 characters" do
      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.create_user("shortpw", "short", "short")
    end

    test "fails when passwords do not match" do
      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.create_user("mismatch", "password123", "different123")
    end
  end

  # ---------------------------------------------------------------------------
  # generate_recovery_codes
  # ---------------------------------------------------------------------------

  describe "generate_recovery_codes" do
    test "returns plain codes in metadata, stores hashed codes in DB" do
      user = create_user()

      {:ok, updated_user} = Accounts.generate_recovery_codes(user, actor: user)

      plain_codes = updated_user.__metadata__.plain_recovery_codes
      hashed_codes = updated_user.recovery_codes

      assert plain_codes != []
      assert length(hashed_codes) == length(plain_codes)

      # Plain codes are not stored as-is — every DB code is a hash
      for plain <- plain_codes do
        refute plain in hashed_codes
        assert Enum.any?(hashed_codes, &Argon2.verify_pass(plain, &1))
      end
    end

    test "regenerating codes replaces previous codes entirely" do
      user = create_user()

      {:ok, first} = Accounts.generate_recovery_codes(user, actor: user)
      first_plain = first.__metadata__.plain_recovery_codes

      {:ok, second} = Accounts.generate_recovery_codes(first, actor: first)
      second_plain = second.__metadata__.plain_recovery_codes

      # No code from the first set should appear in the second set
      assert MapSet.disjoint?(MapSet.new(first_plain), MapSet.new(second_plain))
    end

    test "anonymous users cannot generate recovery codes" do
      anon = create_anonymous()

      assert {:error, _} = Accounts.generate_recovery_codes(anon, actor: anon)
    end
  end

  # ---------------------------------------------------------------------------
  # reset_password_with_recovery_code
  # ---------------------------------------------------------------------------

  describe "reset_password_with_recovery_code" do
    setup do
      user = create_user()
      {:ok, user_with_codes} = Accounts.generate_recovery_codes(user, actor: user)
      plain_codes = user_with_codes.__metadata__.plain_recovery_codes
      %{user: user_with_codes, plain_codes: plain_codes}
    end

    test "succeeds with a valid recovery code", %{user: user, plain_codes: [code | _]} do
      assert {:ok, _updated} =
               Accounts.reset_password_with_recovery_code(user, code, "newsecurepassword")
    end

    test "consumes the recovery code so it cannot be used again", %{
      user: user,
      plain_codes: [code | _]
    } do
      {:ok, user_after_reset} =
        Accounts.reset_password_with_recovery_code(user, code, "newsecurepassword")

      # The same code should now fail
      assert {:error, _} =
               Accounts.reset_password_with_recovery_code(user_after_reset, code, "anotherpass")
    end

    test "fails with an incorrect recovery code", %{user: user} do
      assert {:error, _} =
               Accounts.reset_password_with_recovery_code(user, "WRONGCODE00", "newpassword123")
    end
  end

  # ---------------------------------------------------------------------------
  # convert_to_registered
  # ---------------------------------------------------------------------------

  describe "convert_to_registered" do
    test "converts an anonymous user to registered" do
      anon = create_anonymous()

      {:ok, registered} =
        Accounts.convert_to_registered(
          anon,
          "newusername",
          "password123",
          "password123",
          actor: anon
        )

      assert to_string(registered.username) == "newusername"
      refute registered.is_anonymous
      assert registered.hashed_password != nil
    end

    test "fails if the user is already registered" do
      user = create_user()

      assert {:error, _} =
               Accounts.convert_to_registered(
                 user,
                 "otherusername",
                 "password123",
                 "password123",
                 actor: user
               )
    end
  end

  # ---------------------------------------------------------------------------
  # change_username (rate limiting)
  # ---------------------------------------------------------------------------

  describe "change_username" do
    test "succeeds when username_last_changed is nil (first ever change)" do
      user = create_user()

      # username_last_changed is nil on a fresh user
      assert is_nil(user.username_last_changed)

      {:ok, updated} = Accounts.change_username(user, "newname123", actor: user)

      assert to_string(updated.username) == "newname123"
    end

    test "blocks a second change within the cooldown period" do
      user = create_user()

      {:ok, after_first_change} = Accounts.change_username(user, "firstchange", actor: user)

      # Immediately try to change again — should be blocked by rate limit
      assert {:error, error} =
               Accounts.change_username(after_first_change, "secondchange",
                 actor: after_first_change
               )

      assert %Ash.Error.Invalid{} = error

      # Verify the error mentions the rate limit
      error_messages = Exception.message(error)
      assert error_messages =~ "days remaining" or error_messages =~ "can only be changed"
    end
  end
end
