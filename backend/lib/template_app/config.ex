defmodule TemplateApp.Config do
  @moduledoc """
  Centralized configuration module for the application template.

  Provides a clean interface for reading configuration values from
  environment variables.
  """

  def registration_enabled? do
    case System.get_env("ENABLE_REGISTRATION", "true") do
      "false" -> false
      "0" -> false
      _ -> true
    end
  end

  @default_username_cooldown_days 30
  @max_username_cooldown_days 3650
  @default_recovery_code_count 6
  @max_recovery_code_count 20
  @default_recovery_code_ttl_seconds 3600
  @min_recovery_code_ttl_seconds 60
  @max_recovery_code_ttl_seconds 2_592_000

  @doc "Validates all environment-backed account configuration values."
  def validate! do
    username_change_cooldown_days()
    recovery_code_count()
    recovery_code_ttl_seconds()
    :ok
  end

  def username_change_cooldown_days do
    parse_optional_integer(
      "USERNAME_COOLDOWN_DAYS",
      @default_username_cooldown_days,
      0,
      @max_username_cooldown_days
    )
  end

  def recovery_code_count do
    parse_optional_integer(
      "RECOVERY_CODE_COUNT",
      @default_recovery_code_count,
      0,
      @max_recovery_code_count
    )
  end

  def recovery_code_ttl_seconds do
    parse_optional_integer(
      "RECOVERY_CODE_TTL_SECONDS",
      @default_recovery_code_ttl_seconds,
      @min_recovery_code_ttl_seconds,
      @max_recovery_code_ttl_seconds
    )
  end

  @doc false
  def parse_username_change_cooldown_days(value),
    do: parse_integer("USERNAME_COOLDOWN_DAYS", value, 0, @max_username_cooldown_days)

  @doc false
  def parse_recovery_code_count(value),
    do: parse_integer("RECOVERY_CODE_COUNT", value, 0, @max_recovery_code_count)

  @doc false
  def parse_recovery_code_ttl_seconds(value),
    do:
      parse_integer(
        "RECOVERY_CODE_TTL_SECONDS",
        value,
        @min_recovery_code_ttl_seconds,
        @max_recovery_code_ttl_seconds
      )

  defp parse_optional_integer(variable, default, min, max) do
    case System.get_env(variable) do
      nil -> default
      value -> parse_integer(variable, value, min, max)
    end
  end

  defp parse_integer(variable, value, min, max) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer in min..max//1 -> integer
      _ -> raise ArgumentError, "#{variable} must be an integer between #{min} and #{max}"
    end
  end

  defp parse_integer(variable, _value, min, max) do
    raise ArgumentError, "#{variable} must be an integer between #{min} and #{max}"
  end
end
