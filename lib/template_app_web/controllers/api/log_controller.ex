defmodule TemplateAppWeb.Api.LogController do
  @moduledoc """
  Ingests frontend logs for server-side logging.

  Rate limited to 20 requests per minute per IP address.
  Only accepts 'warn' and 'error' level logs.
  """

  use TemplateAppWeb, :controller

  require Logger

  @allowed_levels ~w(warn error)
  @rate_limit 20
  @rate_window_ms 60_000

  plug :rate_limit

  @doc """
  Accepts log payloads from the frontend and logs them server-side.

  ## Expected payload

      {
        "level": "error" | "warn",
        "message": "Error description",
        "context": {
          "url": "/dashboard",
          "user_agent": "Mozilla/5.0...",
          "timestamp": "2026-01-04T12:00:00Z",
          "component_stack": "...",  // optional
          "error_id": "..."           // optional, if displaying server error
        }
      }

  ## Response

      {"ok": true}
  """
  def create(conn, %{"level" => level, "message" => message, "context" => context})
      when level in @allowed_levels do
    log_level = String.to_existing_atom(level)

    Logger.log(log_level, "[Frontend] #{message}",
      client_url: context["url"],
      client_user_agent: truncate(context["user_agent"], 200),
      client_timestamp: context["timestamp"],
      client_error_id: context["error_id"],
      remote_ip: format_ip(conn.remote_ip)
    )

    json(conn, %{ok: true})
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{ok: false, error: "Invalid log payload"})
  end

  # Rate limiting plug using ETS
  defp rate_limit(conn, _opts) do
    table = ensure_rate_limit_table()
    ip = format_ip(conn.remote_ip)
    now = System.monotonic_time(:millisecond)

    case check_rate_limit(table, ip, now) do
      :ok ->
        conn

      :rate_limited ->
        conn
        |> put_status(429)
        |> json(%{ok: false, error: "Rate limit exceeded. Try again later."})
        |> halt()
    end
  end

  defp ensure_rate_limit_table do
    table_name = :log_rate_limit

    case :ets.whereis(table_name) do
      :undefined ->
        :ets.new(table_name, [:set, :public, :named_table])

      _table ->
        table_name
    end
  end

  defp check_rate_limit(table, ip, now) do
    window_start = now - @rate_window_ms

    case :ets.lookup(table, ip) do
      [] ->
        :ets.insert(table, {ip, [now]})
        :ok

      [{^ip, timestamps}] ->
        # Filter out timestamps outside the window
        valid_timestamps = Enum.filter(timestamps, &(&1 > window_start))

        if length(valid_timestamps) >= @rate_limit do
          :rate_limited
        else
          :ets.insert(table, {ip, [now | valid_timestamps]})
          :ok
        end
    end
  end

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp format_ip(ip), do: to_string(ip)

  defp truncate(nil, _max), do: nil

  defp truncate(str, max) when is_binary(str) do
    if String.length(str) > max do
      String.slice(str, 0, max) <> "..."
    else
      str
    end
  end
end
