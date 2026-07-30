defmodule TemplateAppWeb.Plugs.RateLimitPlug do
  @moduledoc """
  Rate limiting plug for auth endpoints.

  Limits are per IP address. Configure per-action limits by passing `:action`.
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @limits %{
    login: {5, :timer.minutes(1)},
    register: {3, :timer.minutes(1)},
    request_reset: {3, :timer.hours(1)},
    reset_password: {5, :timer.hours(1)}
  }

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    if Application.get_env(:template_app, :env) == :test do
      conn
    else
      check_rate(conn, opts)
    end
  end

  defp check_rate(conn, opts) do
    action = Keyword.fetch!(opts, :action)
    {limit, window} = Map.fetch!(@limits, action)
    key = "#{action}:#{format_ip(conn.remote_ip)}"

    case TemplateApp.RateLimit.hit(key, window, limit) do
      {:allow, _count} ->
        conn

      {:deny, retry_after} ->
        retry_seconds = div(retry_after, 1000) + 1

        conn
        |> put_resp_header("retry-after", Integer.to_string(retry_seconds))
        |> put_status(429)
        |> json(%{error: "rate_limited", message: "Too many requests. Try again later."})
        |> halt()
    end
  end

  defp format_ip(ip) when is_tuple(ip) do
    ip |> Tuple.to_list() |> Enum.join(".")
  end

  defp format_ip(ip), do: to_string(ip)
end
