defmodule TemplateApp.Config do
  @moduledoc """
  Centralized configuration module for the application template.

  Provides a clean interface for reading configuration values from
  environment variables and application config.
  """

  @doc """
  Get the application name for branding and display purposes.
  Defaults to "SAAS Template" if not configured.
  """
  def app_name do
    System.get_env("APP_NAME", "Template App")
  end

  @doc """
  Get the application description for meta tags and branding.
  """
  def app_description do
    System.get_env("APP_DESCRIPTION", "A modern web application built with Phoenix and Ash")
  end

  @doc """
  Get the company name for copyright and legal purposes.
  Defaults to app name if not set separately.
  """
  def company_name do
    System.get_env("COMPANY_NAME", app_name())
  end

  @doc """
  Get the application URL for absolute links and redirects.
  """
  def app_url do
    System.get_env("APP_URL", "http://localhost:4000")
  end

  @doc """
  Check if registration is enabled.
  Allows disabling new user registration for closed systems.
  """
  def registration_enabled? do
    case System.get_env("ENABLE_REGISTRATION", "true") do
      "false" -> false
      "0" -> false
      _ -> true
    end
  end

  @doc """
  Get the default theme/color scheme.
  Prepared for future theme customization.
  """
  def default_theme do
    System.get_env("DEFAULT_THEME", "light")
  end

  @doc """
  Get the username change cooldown period in days.
  Users can only change their username once within this period.
  """
  def username_change_cooldown_days do
    case System.get_env("USERNAME_COOLDOWN_DAYS") do
      nil -> 30
      val -> String.to_integer(val)
    end
  end

  @doc """
  Get the number of recovery codes to generate.
  """
  def recovery_code_count do
    case System.get_env("RECOVERY_CODE_COUNT") do
      nil -> 6
      val -> String.to_integer(val)
    end
  end

  @doc """
  Get the lifetime of a recovery-code batch, in seconds.

  A batch of recovery codes (used both for self-service backup codes and the
  unauthenticated password-reset flow) is only valid for this long after it was
  generated. Defaults to 1 hour.
  """
  def recovery_code_ttl_seconds do
    case System.get_env("RECOVERY_CODE_TTL_SECONDS") do
      nil -> 3600
      val -> String.to_integer(val)
    end
  end

  @doc """
  Get feature flags as a map for easy checking.
  """
  def features do
    %{
      registration: registration_enabled?(),
      # Not implemented in current template
      email: false
    }
  end

  @doc """
  Get branding configuration as a map.
  """
  def branding do
    %{
      name: app_name(),
      description: app_description(),
      company: company_name(),
      url: app_url(),
      theme: default_theme()
    }
  end
end
