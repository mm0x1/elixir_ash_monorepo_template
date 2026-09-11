defmodule TemplateAppWeb.Helpers.ApiResponseTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias TemplateAppWeb.Helpers.ApiResponse

  test "maps unknown validation failures to a generic 500 response" do
    conn = Phoenix.ConnTest.build_conn()

    log =
      capture_log([level: :error], fn ->
        conn =
          ApiResponse.validation_error(
            conn,
            RuntimeError.exception("password=super-secret refresh_token=token-value"),
            "Registration failed"
          )

        assert conn.status == 500

        assert Jason.decode!(conn.resp_body) == %{
                 "error" => "internal_error",
                 "message" => "Something went wrong"
               }
      end)

    refute log =~ "super-secret"
    refute log =~ "token-value"
  end

  test "preserves known safe Ash validation messages" do
    error =
      Ash.Error.Changes.InvalidAttribute.exception(
        field: :password,
        message: "must be at least 8 characters"
      )

    invalid = Ash.Error.Invalid.exception(errors: [error])
    conn = ApiResponse.validation_error(Phoenix.ConnTest.build_conn(), invalid, "Request failed")

    assert conn.status == 422
    assert %{"error" => "validation_error", "message" => message} = Jason.decode!(conn.resp_body)
    assert message == "Password must be at least 8 characters"
  end
end
