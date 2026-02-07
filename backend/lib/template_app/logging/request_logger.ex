defmodule TemplateApp.Logging.RequestLogger do
  @moduledoc """
  Verbose request logging for development.

  Logs request details including path, method, params, and response status.
  Only logs in development environment for debugging purposes.

  ## Usage

  Add to your endpoint.ex:

      plug TemplateApp.Logging.RequestLogger

  Or in a specific pipeline in router.ex:

      plug TemplateApp.Logging.RequestLogger
  """

  @behaviour Plug

  require Logger

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if Application.get_env(:template_app, :env, :dev) != :prod do
      start_time = System.monotonic_time()

      Plug.Conn.register_before_send(conn, fn conn ->
        stop_time = System.monotonic_time()
        duration_us = System.convert_time_unit(stop_time - start_time, :native, :microsecond)
        duration_ms = Float.round(duration_us / 1000, 2)

        Logger.debug("Request completed",
          method: conn.method,
          path: conn.request_path,
          status: conn.status,
          duration_ms: duration_ms,
          params: sanitize_params(conn.params),
          remote_ip: format_ip(conn.remote_ip)
        )

        conn
      end)
    else
      conn
    end
  end

  defp sanitize_params(params) when is_map(params) do
    params
    |> Map.drop(["password", "password_confirmation", "token", "secret", "_csrf_token"])
    |> inspect(limit: 500, pretty: false)
  end

  defp sanitize_params(params), do: inspect(params, limit: 500)

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp format_ip(ip), do: to_string(ip)
end
