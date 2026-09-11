defmodule TemplateAppWeb.Plugs.RateLimitPlug do
  @moduledoc """
  Rate limits public authentication operations.

  The limiter remains active in test mode; test requests use a process-scoped
  key suffix so independent tests do not share counters. Forwarded client IPs
  are considered only when the immediate peer is explicitly trusted.
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @default_limits %{
    login: %{ip: {5, :timer.minutes(1)}, account: {5, :timer.minutes(1)}},
    register: %{ip: {3, :timer.minutes(1)}, account: {3, :timer.minutes(1)}},
    refresh: %{ip: {10, :timer.minutes(1)}},
    reset_password: %{ip: {5, :timer.hours(1)}, account: {5, :timer.hours(1)}},
    logout: %{ip: {20, :timer.minutes(1)}}
  }

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    action = Keyword.fetch!(opts, :action)
    limits = Keyword.get(opts, :limits) || Application.get_env(:template_app, :rate_limits)
    limiter = Keyword.get(opts, :limiter) || Application.get_env(:template_app, :rate_limiter)
    trusted_proxy_ips = Keyword.get(opts, :trusted_proxy_ips)
    limits = limits || @default_limits
    limiter = limiter || TemplateApp.RateLimit

    case check_dimensions(conn, action, limits, limiter, trusted_proxy_ips) do
      :allow ->
        conn

      {:deny, retry_after} ->
        retry_seconds = div(max(retry_after, 0), 1000) + 1

        conn
        |> put_resp_header("retry-after", Integer.to_string(retry_seconds))
        |> put_status(429)
        |> json(%{error: "rate_limited", message: "Too many requests. Try again later."})
        |> halt()
    end
  end

  @doc false
  def default_limits, do: @default_limits

  @doc false
  def client_ip(conn, trusted_proxy_ips \\ nil) do
    if trusted_proxy?(conn.remote_ip, trusted_proxy_ips) do
      forwarded_ip(conn) || conn.remote_ip
    else
      conn.remote_ip
    end
  end

  defp check_dimensions(conn, action, limits, limiter, trusted_proxy_ips) do
    dimensions = dimensions(action, conn, trusted_proxy_ips)

    Enum.reduce_while(dimensions, :allow, fn {dimension, value}, :allow ->
      case get_limit(limits, action, dimension) do
        nil ->
          {:cont, :allow}

        {limit, window} ->
          key = rate_key(action, dimension, value)

          case limiter.hit(key, window, limit) do
            {:allow, _count} -> {:cont, :allow}
            {:deny, retry_after} -> {:halt, {:deny, retry_after}}
          end
      end
    end)
  end

  defp get_limit(limits, action, dimension) do
    limits
    |> Map.get(action, %{})
    |> Map.get(dimension)
  end

  defp dimensions(action, conn, trusted_proxy_ips)
       when action in [:login, :register, :reset_password] do
    account_dimension = account_dimension(conn)

    case account_dimension do
      nil -> [{:ip, format_ip(client_ip(conn, trusted_proxy_ips))}]
      value -> [{:ip, format_ip(client_ip(conn, trusted_proxy_ips))}, {:account, value}]
    end
  end

  defp dimensions(_action, conn, trusted_proxy_ips),
    do: [{:ip, format_ip(client_ip(conn, trusted_proxy_ips))}]

  defp rate_key(action, dimension, value) do
    scope =
      if Application.get_env(:template_app, :env) == :test, do: inspect(self()), else: "global"

    "#{scope}:#{action}:#{dimension}:#{value}"
  end

  defp account_dimension(conn) do
    case conn.params do
      %{"username" => username} when is_binary(username) and username != "" ->
        username
        |> String.trim()
        |> String.downcase()
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)
        |> binary_part(0, 16)

      _ ->
        nil
    end
  end

  defp trusted_proxy?(remote_ip, nil) do
    trusted_proxy?(remote_ip, Application.get_env(:template_app, :trusted_proxy_ips, []))
  end

  defp trusted_proxy?(remote_ip, trusted_proxy_ips), do: remote_ip in trusted_proxy_ips

  defp forwarded_ip(conn) do
    conn
    |> get_req_header("x-forwarded-for")
    |> List.first()
    |> case do
      nil -> nil
      value -> value |> String.split(",") |> Enum.find_value(&parse_ip/1)
    end
  end

  defp parse_ip(value) do
    case value |> String.trim() |> to_charlist() |> :inet.parse_address() do
      {:ok, ip} -> ip
      {:error, :einval} -> nil
    end
  end

  defp format_ip(ip) when is_tuple(ip) do
    case :inet.ntoa(ip) do
      {:error, :einval} -> ip |> Tuple.to_list() |> Enum.join(".")
      address -> to_string(address)
    end
  end

  defp format_ip(ip), do: to_string(ip)
end
