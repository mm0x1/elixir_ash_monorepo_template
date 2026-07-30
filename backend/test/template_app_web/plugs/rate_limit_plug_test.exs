defmodule TemplateAppWeb.Plugs.RateLimitPlugTest do
  use TemplateAppWeb.ConnCase, async: true

  alias TemplateAppWeb.Plugs.RateLimitPlug

  setup do
    # Override env to enable rate limiting in this test
    original = Application.get_env(:template_app, :env)
    Application.put_env(:template_app, :env, :dev)
    on_exit(fn -> Application.put_env(:template_app, :env, original) end)
    :ok
  end

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
end
