defmodule TemplateApp.Config do
  @moduledoc """
  Centralized configuration module for the SAAS template.

  This module provides a clean interface for reading configuration values
  from environment variables and application config, making it easy to
  customize the template for different SAAS applications.
  """

  @doc """
  Get the application name for branding and display purposes.
  Defaults to "SAAS Template" if not configured.
  """
  def app_name do
    System.get_env("APP_NAME", "SAAS Template")
  end

  @doc """
  Get the application description for meta tags and branding.
  """
  def app_description do
    System.get_env("APP_DESCRIPTION", "A modern SAAS application built with Phoenix and Ash")
  end

  @doc """
  Get the company name for copyright and legal purposes.
  Defaults to app name if not set separately.
  """
  def company_name do
    System.get_env("COMPANY_NAME", app_name())
  end

  @doc """
  Get the support email (if email functionality is added later).
  Not used in current template but prepared for future use.
  """
  def support_email do
    System.get_env("SUPPORT_EMAIL")
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
