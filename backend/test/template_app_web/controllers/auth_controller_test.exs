defmodule TemplateAppWeb.AuthControllerTest do
  # async: false required because the RefreshToken create action uses manage_relationship
  # which may spawn Ash internal processes outside the sandbox ownership chain.
  # Shared sandbox mode (async: false) lets all spawned processes access test data.
  use TemplateAppWeb.ConnCase, async: false

  import Ecto.Query
  import TemplateApp.UserFixtures

  alias TemplateApp.Accounts.Resources.RefreshToken

  require Ash.Query

  @refresh_cookie "_template_app_refresh"

  # Returns a conn with Bearer token set
  defp authenticate(conn, user) do
    token = access_token_for(user)
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

  # Extracts the refresh cookie value from a response conn
  defp get_resp_cookie(conn) do
    case conn.resp_cookies[@refresh_cookie] do
      %{value: value} when value != "" -> {:ok, value}
      _ -> :error
    end
  end

  # Builds a new conn with the given refresh cookie set
  defp with_refresh_cookie(token_id) do
    Plug.Test.put_req_cookie(build_conn(), @refresh_cookie, token_id)
  end

  # Creates a RefreshToken in the database directly (test-process DB access)
  defp create_refresh_token(user) do
    {:ok, token} =
      RefreshToken
      |> Ash.Changeset.for_create(:create, %{
        user_id: user.id,
        device_name: "test-device",
        version: user.token_version
      })
      |> Ash.create()

    token
  end

  # ---------------------------------------------------------------------------
  # Login
  # ---------------------------------------------------------------------------

  describe "POST /auth/login" do
    test "returns access_token and sets refresh cookie with valid credentials", %{conn: conn} do
      create_user(%{username: "logintest", password: "password123"})

      conn = post(conn, ~p"/auth/login", %{username: "logintest", password: "password123"})

      assert %{"access_token" => token, "user" => user} = json_response(conn, 200)
      assert is_binary(token)
      assert user["username"] == "logintest"
      assert {:ok, _cookie_id} = get_resp_cookie(conn)
    end

    test "returns 401 for wrong password", %{conn: conn} do
      create_user(%{username: "logintest2", password: "password123"})

      conn = post(conn, ~p"/auth/login", %{username: "logintest2", password: "wrongpassword"})

      assert %{"error" => "invalid_credentials"} = json_response(conn, 401)
    end

    test "returns 400 when params are missing", %{conn: conn} do
      conn = post(conn, ~p"/auth/login", %{username: "onlyusername"})

      assert %{"error" => "bad_request"} = json_response(conn, 400)
    end
  end

  # ---------------------------------------------------------------------------
  # Register
  # ---------------------------------------------------------------------------

  describe "POST /auth/register" do
    test "creates user and returns access_token with 201", %{conn: conn} do
      conn =
        post(conn, ~p"/auth/register", %{
          username: "newuser",
          password: "password123",
          password_confirmation: "password123"
        })

      assert %{"access_token" => token, "user" => user} = json_response(conn, 201)
      assert is_binary(token)
      assert user["username"] == "newuser"
      refute user["is_anonymous"]
      assert {:ok, _} = get_resp_cookie(conn)
    end

    test "returns 422 for duplicate username", %{conn: conn} do
      create_user(%{username: "duplicate"})

      conn =
        post(conn, ~p"/auth/register", %{
          username: "duplicate",
          password: "password123",
          password_confirmation: "password123"
        })

      assert %{"error" => "validation_error"} = json_response(conn, 422)
    end

    test "returns 422 when passwords don't match", %{conn: conn} do
      conn =
        post(conn, ~p"/auth/register", %{
          username: "pwmismatch",
          password: "password123",
          password_confirmation: "different123"
        })

      assert %{"error" => "validation_error"} = json_response(conn, 422)
    end

    test "returns 422 when password is too short", %{conn: conn} do
      conn =
        post(conn, ~p"/auth/register", %{
          username: "shortpw",
          password: "short",
          password_confirmation: "short"
        })

      assert %{"error" => "validation_error"} = json_response(conn, 422)
    end

    test "returns 400 when params are missing", %{conn: conn} do
      conn = post(conn, ~p"/auth/register", %{username: "incomplete"})

      assert %{"error" => "bad_request"} = json_response(conn, 400)
    end
  end

  # ---------------------------------------------------------------------------
  # Refresh
  # ---------------------------------------------------------------------------

  describe "POST /auth/refresh" do
    test "rotates the refresh token: new access token, new cookie, old token deleted", %{
      conn: _conn
    } do
      user = create_user()
      old_token = create_refresh_token(user)

      conn = post(with_refresh_cookie(old_token.id), ~p"/auth/refresh")

      assert %{"access_token" => access_token} = json_response(conn, 200)
      assert is_binary(access_token)

      {:ok, new_cookie_id} = get_resp_cookie(conn)
      assert new_cookie_id != old_token.id

      assert {:ok, nil} =
               RefreshToken
               |> Ash.Query.filter(id == ^old_token.id)
               |> Ash.read_one()
    end

    test "rotated refresh token can be used for a subsequent refresh", %{conn: _conn} do
      user = create_user()
      token = create_refresh_token(user)

      first_conn = post(with_refresh_cookie(token.id), ~p"/auth/refresh")
      assert %{"access_token" => _} = json_response(first_conn, 200)
      {:ok, rotated_id} = get_resp_cookie(first_conn)

      second_conn = post(with_refresh_cookie(rotated_id), ~p"/auth/refresh")
      assert %{"access_token" => _} = json_response(second_conn, 200)
    end

    test "returns 401 when no refresh cookie is present", %{conn: conn} do
      conn = post(conn, ~p"/auth/refresh")

      assert %{"error" => "no_refresh_token"} = json_response(conn, 401)
    end

    test "returns 401 when refresh cookie contains a non-existent token ID", %{conn: _conn} do
      fake_id = Ecto.UUID.generate()
      conn = post(with_refresh_cookie(fake_id), ~p"/auth/refresh")

      assert %{"error" => "invalid_refresh_token"} = json_response(conn, 401)
      assert conn.resp_cookies[@refresh_cookie].max_age == 0
    end

    test "returns 401 when refresh token is expired", %{conn: _conn} do
      user = create_user()
      token = create_refresh_token(user)

      # Expire the token directly via Ecto
      TemplateApp.Repo.update_all(
        from(t in RefreshToken, where: t.id == ^token.id),
        set: [expires_at: ~U[2020-01-01 00:00:00Z]]
      )

      conn = post(with_refresh_cookie(token.id), ~p"/auth/refresh")

      assert %{"error" => "token_expired"} = json_response(conn, 401)
      assert conn.resp_cookies[@refresh_cookie].max_age == 0
    end

    test "returns 401 after logout_all (version mismatch)", %{conn: _conn} do
      user = create_user()
      token = create_refresh_token(user)
      access_token = access_token_for(user)

      # Logout all devices — increments user.token_version from 1 to 2
      post(
        put_req_header(build_conn(), "authorization", "Bearer #{access_token}"),
        ~p"/auth/logout_all"
      )

      # The refresh token still has version: 1, but user now has token_version: 2
      conn = post(with_refresh_cookie(token.id), ~p"/auth/refresh")

      assert %{"error" => "token_revoked"} = json_response(conn, 401)
      assert conn.resp_cookies[@refresh_cookie].max_age == 0
    end
  end

  # ---------------------------------------------------------------------------
  # Logout
  # ---------------------------------------------------------------------------

  describe "POST /auth/logout" do
    test "clears the refresh cookie and returns success", %{conn: _conn} do
      user = create_user()
      token = create_refresh_token(user)
      access_token = access_token_for(user)

      base_conn = with_refresh_cookie(token.id)

      conn =
        base_conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/auth/logout")

      assert %{"message" => "Logged out successfully"} = json_response(conn, 200)
      assert conn.resp_cookies[@refresh_cookie].max_age == 0
    end

    test "returns success even when no cookie present", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> authenticate(user)
        |> post(~p"/auth/logout")

      assert %{"message" => "Already logged out"} = json_response(conn, 200)
    end
  end

  # ---------------------------------------------------------------------------
  # Logout All
  # ---------------------------------------------------------------------------

  describe "POST /auth/logout_all" do
    test "invalidates existing refresh tokens for the user", %{conn: _conn} do
      user = create_user()
      token = create_refresh_token(user)
      access_token = access_token_for(user)

      # Logout all devices
      auth_conn = put_req_header(build_conn(), "authorization", "Bearer #{access_token}")

      logout_conn = post(auth_conn, ~p"/auth/logout_all")

      assert %{"message" => "Logged out from all devices"} = json_response(logout_conn, 200)
      assert logout_conn.resp_cookies[@refresh_cookie].max_age == 0

      # The pre-existing refresh token should now be rejected
      refresh_conn = post(with_refresh_cookie(token.id), ~p"/auth/refresh")
      assert %{"error" => "token_revoked"} = json_response(refresh_conn, 401)
    end
  end

  # ---------------------------------------------------------------------------
  # Me
  # ---------------------------------------------------------------------------

  describe "GET /auth/me" do
    test "returns current user with expected fields", %{conn: conn} do
      user = create_user(%{username: "metest"})

      conn =
        conn
        |> authenticate(user)
        |> get(~p"/auth/me")

      assert %{"user" => returned_user} = json_response(conn, 200)
      assert returned_user["id"] == user.id
      assert returned_user["username"] == "metest"
      assert returned_user["is_anonymous"] == false
      assert returned_user["has_recovery_codes"] == false
      assert returned_user["role"] == "user"
    end
  end
end
