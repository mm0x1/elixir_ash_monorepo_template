defmodule TemplateAppWeb.AuthRateLimitControllerTest do
  use TemplateAppWeb.ConnCase, async: true

  defp json_request(conn, path, params), do: json_post(conn, path, params)

  defp with_refresh_cookie(token_id) do
    Plug.Test.put_req_cookie(build_conn(), "_template_app_refresh", token_id)
  end

  test "limits repeated login attempts", %{conn: conn} do
    for _ <- 1..5 do
      response =
        json_request(conn, ~p"/auth/login", %{username: "missing", password: "password123"})

      assert response.status == 401
    end

    response =
      json_request(conn, ~p"/auth/login", %{username: "missing", password: "password123"})

    assert response.status == 429
    assert [retry_after] = get_resp_header(response, "retry-after")
    assert String.to_integer(retry_after) > 0
  end

  test "limits repeated registration attempts", %{conn: conn} do
    for _ <- 1..3 do
      response = json_request(conn, ~p"/auth/register", %{username: "register-user"})
      assert response.status == 400
    end

    assert json_request(conn, ~p"/auth/register", %{username: "register-user"}).status == 429
  end

  test "limits refresh attempts without a valid cookie", %{conn: conn} do
    for _ <- 1..10 do
      assert post(conn, ~p"/auth/refresh").status == 401
    end

    assert post(conn, ~p"/auth/refresh").status == 429
  end

  test "limits invalid refresh-cookie attempts", %{conn: _conn} do
    for _ <- 1..10 do
      assert post(with_refresh_cookie(Ecto.UUID.generate()), ~p"/auth/refresh").status == 401
    end

    assert post(with_refresh_cookie(Ecto.UUID.generate()), ~p"/auth/refresh").status == 429
  end

  test "limits password reset completion attempts", %{conn: conn} do
    for _ <- 1..5 do
      response = json_request(conn, ~p"/auth/reset-password", %{username: "reset-user"})
      assert response.status == 400
    end

    assert json_request(conn, ~p"/auth/reset-password", %{username: "reset-user"}).status == 429
  end

  test "limits public device logout attempts", %{conn: conn} do
    for _ <- 1..20 do
      assert post(conn, ~p"/auth/logout").status == 200
    end

    assert post(conn, ~p"/auth/logout").status == 429
  end
end
