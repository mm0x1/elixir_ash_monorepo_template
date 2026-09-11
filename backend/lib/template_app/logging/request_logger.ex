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

  import Plug.Conn, only: [get_resp_header: 2]

  require Logger

  @sensitive_keys MapSet.new([
                    "password",
                    "passwordconfirmation",
                    "newpassword",
                    "recoverycode",
                    "recoverycodes",
                    "hashedpassword",
                    "token",
                    "accesstoken",
                    "refreshtoken",
                    "refreshid",
                    "sessionid",
                    "jti",
                    "authorization",
                    "cookie",
                    "cookies",
                    "secret",
                    "csrf-token",
                    "x-csrf-token",
                    "csrftoken"
                  ])

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
          request_id: List.first(get_resp_header(conn, "x-request-id")),
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
    |> redact_params()
    |> inspect(limit: 500, pretty: false)
  end

  defp sanitize_params(params), do: inspect(params, limit: 500)

  @doc false
  def redact_params(params), do: redact_value(params)

  defp redact_value(%_{}), do: "[REDACTED]"

  defp redact_value(%{} = map) do
    Enum.into(map, %{}, fn {key, value} ->
      if sensitive_key?(key) do
        {key, "[REDACTED]"}
      else
        {key, redact_value(value)}
      end
    end)
  end

  defp redact_value(list) when is_list(list), do: Enum.map(list, &redact_value/1)
  defp redact_value(value), do: value

  defp sensitive_key?(key) when is_atom(key), do: key |> Atom.to_string() |> sensitive_key?()

  defp sensitive_key?(key) when is_binary(key) do
    normalized = String.replace(String.downcase(key), ~r/[^a-z0-9-]/, "")
    MapSet.member?(@sensitive_keys, normalized)
  end

  defp sensitive_key?(_key), do: false

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp format_ip(ip), do: to_string(ip)
end
