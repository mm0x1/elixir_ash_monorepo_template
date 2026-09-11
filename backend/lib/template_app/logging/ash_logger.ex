defmodule TemplateApp.Logging.AshLogger do
  @moduledoc """
  Telemetry handler for logging Ash action execution with timing.

  Attaches to Ash telemetry events and logs action execution details
  including domain, resource, action name, and duration.

  ## Setup

  Add to your Application.start/2:

      TemplateApp.Logging.AshLogger.attach()

  ## Configuration

  Logging level can be configured via config:

      config :template_app, :ash_logger,
        enabled: true,
        log_level: :debug,
        slow_threshold_ms: 100  # Log slow queries at :info level
  """

  require Logger

  @events [
    [:ash, :action, :start],
    [:ash, :action, :stop],
    [:ash, :action, :exception]
  ]

  @doc """
  Attaches the telemetry handlers for Ash action logging.
  """
  def attach do
    :telemetry.attach_many(
      "ash-logger",
      @events,
      &handle_event/4,
      nil
    )
  end

  @doc """
  Detaches the telemetry handlers.
  """
  def detach do
    :telemetry.detach("ash-logger")
  end

  @doc false
  def handle_event([:ash, :action, :start], _measurements, metadata, _config) do
    if enabled?() do
      Logger.debug("Ash action started",
        domain: metadata[:domain],
        resource: metadata[:resource],
        action: metadata[:action],
        action_type: metadata[:action_type]
      )
    end
  end

  def handle_event([:ash, :action, :stop], measurements, metadata, _config) do
    if enabled?() do
      duration_us = measurements[:duration] || 0
      duration_ms = Float.round(duration_us / 1_000, 2)

      log_level = determine_log_level(duration_ms)

      Logger.log(log_level, "Ash action completed",
        domain: metadata[:domain],
        resource: metadata[:resource],
        action: metadata[:action],
        action_type: metadata[:action_type],
        duration_ms: duration_ms
      )
    end
  end

  def handle_event([:ash, :action, :exception], _measurements, metadata, _config) do
    if enabled?() do
      Logger.error("Ash action failed",
        domain: metadata[:domain],
        resource: metadata[:resource],
        action: metadata[:action],
        action_type: metadata[:action_type],
        kind: metadata[:kind],
        error_category: error_category(metadata[:reason])
      )
    end
  end

  defp enabled? do
    config()[:enabled] != false &&
      Application.get_env(:template_app, :env, :dev) != :prod
  end

  defp config do
    Application.get_env(:template_app, :ash_logger, [])
  end

  defp determine_log_level(duration_ms) do
    slow_threshold = config()[:slow_threshold_ms] || 100

    if duration_ms >= slow_threshold do
      :info
    else
      config()[:log_level] || :debug
    end
  end

  defp error_category(reason) when is_atom(reason), do: Atom.to_string(reason)

  defp error_category(%{__struct__: module}) when is_atom(module),
    do: "exception:" <> inspect(module)

  defp error_category(_reason), do: "unknown"
end
