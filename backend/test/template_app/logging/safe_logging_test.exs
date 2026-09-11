defmodule TemplateApp.Logging.SafeLoggingTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias TemplateApp.Logging.AshLogger
  alias TemplateApp.Logging.RequestLogger

  test "redacts nested and case-variant credential keys" do
    params = %{
      "PASSWORD" => "password-value",
      "profile" => %{
        "Refresh_Token" => "refresh-value",
        "nested" => [%{"Authorization" => "Bearer token-value"}]
      },
      "display_name" => "visible"
    }

    redacted = RequestLogger.redact_params(params)

    assert redacted["PASSWORD"] == "[REDACTED]"
    assert redacted["profile"]["Refresh_Token"] == "[REDACTED]"
    assert redacted["profile"]["nested"] == [%{"Authorization" => "[REDACTED]"}]
    assert redacted["display_name"] == "visible"
  end

  test "request logs keep the request id without credential values" do
    conn = Phoenix.ConnTest.build_conn(:post, "/auth/login")

    conn =
      conn
      |> Plug.Conn.put_resp_header("x-request-id", "request-id-for-test-1234")
      |> Map.put(:params, %{
        "Password" => "password-value",
        "body" => %{"cookie" => "refresh-cookie", "token" => "access-token"}
      })

    conn = RequestLogger.call(conn, [])

    log =
      capture_log([level: :debug], fn ->
        Plug.Conn.send_resp(conn, 200, "ok")
      end)

    assert log =~ "request-id-for-test-1234"
    refute log =~ "password-value"
    refute log =~ "refresh-cookie"
    refute log =~ "access-token"
  end

  test "Ash exception logs expose only a safe category" do
    reason = RuntimeError.exception("password=secret recovery_code=code refresh_id=id")

    log =
      capture_log([level: :error], fn ->
        AshLogger.handle_event(
          [:ash, :action, :exception],
          %{},
          %{domain: TemplateApp.Accounts, resource: :user, action: :login, reason: reason},
          nil
        )
      end)

    assert log =~ "exception:RuntimeError"
    refute log =~ "password=secret"
    refute log =~ "recovery_code=code"
    refute log =~ "refresh_id=id"
  end
end
