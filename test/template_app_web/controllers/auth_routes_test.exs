defmodule TemplateAppWeb.AuthRoutesTest do
  @moduledoc """
  Tests for authentication route protection.
  """

  use TemplateAppWeb.ConnCase, async: true

  alias TemplateApp.Domains.Accounts

  @unauthenticated_routes ["/auth/sign-in", "/auth/reset-password"]
  @authenticated_routes [
    "/auth/session/sign-out",
    "/auth/recovery-codes",
    "/auth/convert",
    "/profile"
  ]

  describe "unauthenticated routes" do
    test "are accessible when not logged in", %{conn: conn} do
      for path <- @unauthenticated_routes do
        conn = get(conn, path)
        assert conn.status == 200, "Expected 200 for #{path}, got #{conn.status}"
      end
    end

    test "redirect to home when already logged in", %{conn: conn} do
      {:ok, user} = Accounts.create_user("routeuser", "password123", "password123", nil)
      conn = login_user(conn, user)

      for path <- @unauthenticated_routes do
        conn = get(conn, path)
        assert conn.status == 302, "Expected redirect for #{path}"
        assert redirected_to(conn) == "/"
      end
    end
  end

  describe "authenticated routes" do
    test "redirect when not logged in", %{conn: conn} do
      for path <- @authenticated_routes do
        conn = get(conn, path)
        assert conn.status == 302, "Expected redirect for #{path}, got #{conn.status}"
      end
    end

    test "are accessible when logged in", %{conn: conn} do
      {:ok, user} = Accounts.create_user("protecteduser", "password123", "password123", nil)
      conn = login_user(conn, user)

      for path <- @authenticated_routes do
        conn = get(conn, path)
        assert conn.status == 200, "Expected 200 for #{path}, got #{conn.status}"
      end
    end
  end
end
