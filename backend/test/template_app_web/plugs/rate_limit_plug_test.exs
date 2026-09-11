defmodule TemplateAppWeb.Plugs.RateLimitPlugTest do
  use TemplateAppWeb.ConnCase, async: true

  alias TemplateAppWeb.Plugs.RateLimitPlug

  test "allows requests under the limit", %{conn: conn} do
    conn = %{conn | remote_ip: {10, 0, 0, System.unique_integer([:positive])}}
    opts = RateLimitPlug.init(action: :login)
    result = RateLimitPlug.call(conn, opts)
    refute result.halted
  end

  test "returns 429 when rate limit is exceeded", %{conn: conn} do
    ip = {10, 0, 0, System.unique_integer([:positive])}
    opts = RateLimitPlug.init(action: :login)

    for _ <- 1..5 do
      result = RateLimitPlug.call(%{conn | remote_ip: ip}, opts)
      refute result.halted
    end

    result = RateLimitPlug.call(%{conn | remote_ip: ip}, opts)

    assert result.halted
    assert result.status == 429
    assert get_resp_header(result, "retry-after") != []
  end

  test "does not trust forwarded IP headers from an untrusted peer", %{conn: conn} do
    conn =
      conn
      |> Map.put(:remote_ip, {10, 0, 0, 1})
      |> put_req_header("x-forwarded-for", "192.0.2.1")

    refute RateLimitPlug.client_ip(conn) == {192, 0, 2, 1}
    assert RateLimitPlug.client_ip(conn) == {10, 0, 0, 1}
  end

  test "uses a forwarded IP only for a configured trusted peer", %{conn: conn} do
    conn =
      conn
      |> Map.put(:remote_ip, {10, 0, 0, 2})
      |> put_req_header("x-forwarded-for", "192.0.2.2, 10.0.0.2")

    assert RateLimitPlug.client_ip(conn, [{10, 0, 0, 2}]) == {192, 0, 2, 2}
  end

  test "limits an account dimension across different IPs", %{conn: conn} do
    limits = %{login: %{ip: {100, :timer.minutes(1)}, account: {1, :timer.minutes(1)}}}
    username = "account-#{System.unique_integer([:positive])}"
    opts = RateLimitPlug.init(action: :login, limits: limits)

    first =
      conn
      |> Map.put(:remote_ip, {10, 0, 0, 3})
      |> Map.put(:params, %{"username" => username})
      |> RateLimitPlug.call(opts)

    second =
      conn
      |> Map.put(:remote_ip, {10, 0, 0, 4})
      |> Map.put(:params, %{"username" => username})
      |> RateLimitPlug.call(opts)

    refute first.halted
    assert second.halted
    assert second.status == 429
  end
end
