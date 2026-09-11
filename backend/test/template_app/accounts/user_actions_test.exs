defmodule TemplateApp.Accounts.UserActionsTest do
  @moduledoc """
  Tests for non-trivial User resource actions.

  Covers the business rules that the product promises to users and that
  would not be caught by reading the code alone.
  """

  use TemplateApp.DataCase, async: false

  import TemplateApp.UserFixtures

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.Resources.RefreshToken

  defp create_refresh_token(user) do
    {:ok, token} =
      RefreshToken
      |> Ash.Changeset.for_create(:create, %{
        user_id: user.id,
        device_name: "test-device",
        version: user.token_version
      })
      |> Ash.create()

    token
  end

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

    test "fails when password is longer than 128 characters" do
      password = String.duplicate("a", 129)

      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.create_user("longpw", password, password)
    end

    test "fails when passwords do not match" do
      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.create_user("mismatch", "password123", "different123")
    end

    for username <- ["ab", String.duplicate("a", 31), "has-dash", "has space"] do
      test "rejects invalid username #{inspect(username)}" do
        assert {:error, %Ash.Error.Invalid{}} =
                 Accounts.create_user(unquote(username), "password123", "password123")
      end
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

    test "zero configured recovery codes produces an empty batch" do
      previous = System.get_env("RECOVERY_CODE_COUNT")
      System.put_env("RECOVERY_CODE_COUNT", "0")

      on_exit(fn ->
        if previous,
          do: System.put_env("RECOVERY_CODE_COUNT", previous),
          else: System.delete_env("RECOVERY_CODE_COUNT")
      end)

      user = create_user()
      {:ok, updated_user} = Accounts.generate_recovery_codes(user, actor: user)

      assert updated_user.__metadata__.plain_recovery_codes == []
      assert updated_user.recovery_codes == []
      assert is_nil(updated_user.recovery_codes_generated_at)
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

    test "fails when the new password is shorter than 8 characters", %{
      user: user,
      plain_codes: [code | _]
    } do
      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.reset_password_with_recovery_code(user, code, "short")
    end

    test "fails when the new password is longer than 128 characters", %{
      user: user,
      plain_codes: [code | _]
    } do
      password = String.duplicate("a", 129)

      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.reset_password_with_recovery_code(user, code, password)
    end

    test "only one concurrent reset can consume the same recovery code", %{
      user: user,
      plain_codes: [code | _]
    } do
      tasks =
        Enum.map(["firstnewpassword", "secondnewpassword"], fn password ->
          Task.async(fn ->
            Accounts.reset_password_with_recovery_code(user, code, password)
          end)
        end)

      results = Task.await_many(tasks, 15_000)

      assert Enum.count(results, &match?({:ok, _}, &1)) == 1
      assert Enum.count(results, &match?({:error, %Ash.Error.Invalid{}}, &1)) == 1

      {:ok, updated_user} = Accounts.get_user_by_id(user.id)
      assert length(updated_user.recovery_codes) == length(user.recovery_codes) - 1
      assert updated_user.token_version == user.token_version + 1
      refute Enum.any?(updated_user.recovery_codes, &Argon2.verify_pass(code, &1))
    end

    test "rolls back session revocation when the user update fails", %{
      user: user,
      plain_codes: [code | _]
    } do
      refresh_token = create_refresh_token(user)
      max_integer = 9_223_372_036_854_775_807

      TemplateApp.Repo.update_all(
        from(u in TemplateApp.Accounts.Resources.User, where: u.id == ^user.id),
        set: [token_version: max_integer]
      )

      {:ok, current_user} = Accounts.get_user_by_id(user.id)

      assert {:error, _error} =
               Accounts.reset_password_with_recovery_code(
                 current_user,
                 code,
                 "newsecurepassword"
               )

      {:ok, unchanged_user} = Accounts.get_user_by_id(user.id)
      assert unchanged_user.token_version == max_integer
      assert unchanged_user.hashed_password == current_user.hashed_password
      assert Enum.any?(unchanged_user.recovery_codes, &Argon2.verify_pass(code, &1))

      {:ok, [restored_token]} = Accounts.get_refresh_tokens_for_user(user.id)
      assert restored_token.id == refresh_token.id
    end
  end

  # ---------------------------------------------------------------------------
  # convert_to_registered
  # ---------------------------------------------------------------------------

  describe "convert_to_registered" do
    test "anonymous users do not have a password credential or password login" do
      anon = create_anonymous()

      assert is_nil(anon.hashed_password)
      assert {:error, _} = Accounts.sign_in(to_string(anon.username), "password123")
    end

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

    test "uses the shared password policy" do
      anon = create_anonymous()
      password = String.duplicate("a", 129)

      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.convert_to_registered(
                 anon,
                 "longpassword",
                 password,
                 password,
                 actor: anon
               )
    end

    for username <- ["ab", String.duplicate("b", 31), "bad-name"] do
      test "rejects invalid conversion username #{inspect(username)}" do
        anon = create_anonymous()

        assert {:error, %Ash.Error.Invalid{}} =
                 Accounts.convert_to_registered(
                   anon,
                   unquote(username),
                   "password123",
                   "password123",
                   actor: anon
                 )
      end
    end

    test "rejects a password shorter than 8 characters" do
      anon = create_anonymous()

      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.convert_to_registered(
                 anon,
                 "shortpassword",
                 "short",
                 "short",
                 actor: anon
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

    for username <- ["ab", String.duplicate("c", 31), "bad-name"] do
      test "rejects invalid changed username #{inspect(username)}" do
        user = create_user()

        assert {:error, %Ash.Error.Invalid{}} =
                 Accounts.change_username(user, unquote(username), actor: user)
      end
    end

    test "only one concurrent username change can pass the cooldown" do
      user = create_user()

      results =
        ["firstchange", "secondchange"]
        |> Enum.map(fn username ->
          Task.async(fn -> Accounts.change_username(user, username, actor: user) end)
        end)
        |> Task.await_many(15_000)

      assert Enum.count(results, &match?({:ok, _}, &1)) == 1
      assert Enum.count(results, &match?({:error, %Ash.Error.Invalid{}}, &1)) == 1
    end
  end
end
