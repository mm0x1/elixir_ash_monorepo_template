defmodule TemplateAppWeb.CorsAndRequestBoundaryTest do
  use TemplateAppWeb.ConnCase, async: true

  defp preflight(conn, path, origin) do
    conn
    |> put_req_header("origin", origin)
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "content-type, authorization")
    |> options(path)
  end

  describe "CORS preflight" do
    test "allows the documented localhost origin for auth requests", %{conn: conn} do
      conn = preflight(conn, ~p"/auth/login", "http://localhost:5173")

      assert conn.status == 204
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:5173"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]

      assert get_resp_header(conn, "access-control-allow-methods") == [
               "GET,POST,PUT,PATCH,DELETE,OPTIONS"
             ]
    end

    test "allows the documented loopback origin for account requests", %{conn: conn} do
      conn = preflight(conn, ~p"/account/username", "http://127.0.0.1:5173")

      assert conn.status == 204
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://127.0.0.1:5173"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end

    test "does not grant credentialed access to an unknown origin", %{conn: conn} do
      conn = preflight(conn, ~p"/auth/login", "https://attacker.example")

      assert conn.status == 204
      assert get_resp_header(conn, "access-control-allow-origin") == []
      assert get_resp_header(conn, "access-control-allow-credentials") == []
    end
  end

  describe "credentialed API requests" do
    test "returns CORS permission on a JSON auth response", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "http://localhost:5173")
        |> json_post(~p"/auth/login", %{username: "missing", password: "password123"})

      assert conn.status == 401
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:5173"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end
  end

  describe "JSON request boundary" do
    for path <- ["/auth/login", "/auth/register", "/auth/reset-password"] do
      test "rejects form-encoded requests for #{path}", %{conn: conn} do
        conn = post(conn, unquote(path), %{username: "form-user", password: "password123"})

        assert conn.status == 415
        assert get_resp_header(conn, "set-cookie") == []
        assert %{"error" => "unsupported_media_type"} = json_response(conn, 415)
      end
    end

    test "rejects an oversized JSON body before the controller runs", %{conn: conn} do
      body = Jason.encode!(%{"username" => String.duplicate("a", 20_000)})

      assert_raise Plug.Parsers.RequestTooLargeError, fn ->
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/auth/login", body)
      end
    end
  end
end
