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

  def username_change_cooldown_days do
    case System.get_env("USERNAME_COOLDOWN_DAYS") do
      nil -> 30
      val -> String.to_integer(val)
    end
  end

  def recovery_code_count do
    case System.get_env("RECOVERY_CODE_COUNT") do
      nil -> 6
      val -> String.to_integer(val)
    end
  end

  def recovery_code_ttl_seconds do
    case System.get_env("RECOVERY_CODE_TTL_SECONDS") do
      nil -> 3600
      val -> String.to_integer(val)
    end
  end
end
