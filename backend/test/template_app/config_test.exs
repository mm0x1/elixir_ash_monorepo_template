defmodule TemplateApp.ConfigTest do
  use ExUnit.Case, async: true

  alias TemplateApp.Config

  describe "bounded account configuration" do
    test "validates the default startup configuration" do
      assert :ok = Config.validate!()
    end

    test "accepts valid username cooldown values" do
      for {value, expected} <- [{"0", 0}, {"30", 30}, {"3650", 3650}] do
        assert Config.parse_username_change_cooldown_days(value) == expected
      end
    end

    test "rejects invalid username cooldown values" do
      for value <- ["-1", "3651", "not-a-number", "1.5", ""] do
        assert_raise ArgumentError, ~r/USERNAME_COOLDOWN_DAYS/, fn ->
          Config.parse_username_change_cooldown_days(value)
        end
      end
    end

    test "accepts zero and bounded recovery-code counts" do
      for {value, expected} <- [{"0", 0}, {"6", 6}, {"20", 20}] do
        assert Config.parse_recovery_code_count(value) == expected
      end
    end

    test "rejects negative, malformed, and excessive recovery-code counts" do
      for value <- ["-1", "21", "nope", "1.5", ""] do
        assert_raise ArgumentError, ~r/RECOVERY_CODE_COUNT/, fn ->
          Config.parse_recovery_code_count(value)
        end
      end
    end

    test "accepts bounded recovery-code TTL values" do
      assert Config.parse_recovery_code_ttl_seconds("60") == 60
      assert Config.parse_recovery_code_ttl_seconds("3600") == 3600
      assert Config.parse_recovery_code_ttl_seconds("2592000") == 2_592_000
    end

    test "rejects invalid recovery-code TTL values" do
      for value <- ["0", "59", "2592001", "-1", "nope"] do
        assert_raise ArgumentError, ~r/RECOVERY_CODE_TTL_SECONDS/, fn ->
          Config.parse_recovery_code_ttl_seconds(value)
        end
      end
    end

    test "accepts bounded token-cleanup intervals" do
      assert Config.parse_token_cleanup_interval_ms("60000") == 60_000
      assert Config.parse_token_cleanup_interval_ms("3600000") == 3_600_000
      assert Config.parse_token_cleanup_interval_ms("86400000") == 86_400_000
    end

    test "rejects unsafe token-cleanup intervals" do
      for value <- ["59999", "86400001", "-1", "nope"] do
        assert_raise ArgumentError, ~r/TOKEN_CLEANUP_INTERVAL_MS/, fn ->
          Config.parse_token_cleanup_interval_ms(value)
        end
      end
    end
  end
end
