defmodule TemplateAppWeb.AuthApiControllerTest do
  @moduledoc """
  Tests for the authentication API endpoints.
  """

  use TemplateAppWeb.ConnCase, async: true

  describe "POST /api/auth/register" do
    test "creates a user with valid parameters", %{conn: conn} do
      params = %{
        "username" => "newuser",
        "password" => "password123",
        "password_confirmation" => "password123"
      }

      conn = post(conn, "/api/auth/register", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["data"]["user"]["username"] == "newuser"
      assert json["data"]["user"]["id"] != nil
    end

    test "returns error for invalid input", %{conn: conn} do
      # Password too short
      conn =
        post(conn, "/api/auth/register", %{
          "username" => "user1",
          "password" => "short",
          "password_confirmation" => "short"
        })

      assert json_response(conn, 422)["success"] == false

      # Passwords don't match
      conn =
        post(build_conn(), "/api/auth/register", %{
          "username" => "user2",
          "password" => "password123",
          "password_confirmation" => "different"
        })

      assert json_response(conn, 422)["success"] == false
    end

    test "returns error when username is already taken", %{conn: conn} do
      params = %{
        "username" => "duplicateuser",
        "password" => "password123",
        "password_confirmation" => "password123"
      }

      post(conn, "/api/auth/register", params)
      conn = post(conn, "/api/auth/register", params)

      assert json_response(conn, 422)["success"] == false
    end
  end

  describe "POST /api/auth/sign-in" do
    setup %{conn: conn} do
      post(conn, "/api/auth/register", %{
        "username" => "testuser",
        "password" => "password123",
        "password_confirmation" => "password123"
      })

      :ok
    end

    test "signs in with valid credentials", %{conn: conn} do
      conn =
        post(conn, "/api/auth/sign-in", %{
          "username" => "testuser",
          "password" => "password123"
        })

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["data"]["user"]["username"] == "testuser"
    end

    test "returns error for invalid credentials", %{conn: conn} do
      # Wrong password
      conn =
        post(conn, "/api/auth/sign-in", %{
          "username" => "testuser",
          "password" => "wrongpassword"
        })

      assert json_response(conn, 401)["success"] == false

      # Non-existent user
      conn =
        post(build_conn(), "/api/auth/sign-in", %{
          "username" => "nonexistent",
          "password" => "password123"
        })

      assert json_response(conn, 401)["success"] == false
    end
  end

  describe "DELETE /api/auth/session" do
    test "signs out successfully", %{conn: conn} do
      # Register and get authenticated session
      conn =
        post(conn, "/api/auth/register", %{
          "username" => "signoutuser",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      conn = delete(conn, "/api/auth/session")

      assert json_response(conn, 200)["success"] == true
      assert get_session(conn, "user_token") == nil
    end
  end

  describe "POST /api/auth/anonymous" do
    test "creates an anonymous user", %{conn: conn} do
      conn = post(conn, "/api/auth/anonymous")

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["data"]["user"]["is_anonymous"] == true
      assert json["data"]["user"]["id"] != nil
    end
  end

  describe "POST /api/auth/recovery-codes" do
    setup %{conn: conn} do
      conn =
        post(conn, "/api/auth/register", %{
          "username" => "recoveryuser",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      {:ok, conn: conn}
    end

    test "generates recovery codes for authenticated user", %{conn: conn} do
      conn = post(conn, "/api/auth/recovery-codes")

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert is_list(json["data"]["recovery_codes"])
      assert json["data"]["recovery_codes"] != []
    end

    test "requires authentication" do
      conn = post(build_conn(), "/api/auth/recovery-codes")
      assert conn.status in [302, 401, 403]
    end

    test "anonymous users cannot generate recovery codes" do
      anon_conn = post(build_conn(), "/api/auth/anonymous")
      assert json_response(anon_conn, 200)["success"] == true

      anon_conn = post(anon_conn, "/api/auth/recovery-codes")
      assert json_response(anon_conn, 422)["success"] == false
    end
  end

  describe "POST /api/auth/reset-password" do
    setup %{conn: conn} do
      conn =
        post(conn, "/api/auth/register", %{
          "username" => "resetuser",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      conn = post(conn, "/api/auth/recovery-codes")
      codes = json_response(conn, 200)["data"]["recovery_codes"]

      {:ok, codes: codes}
    end

    test "resets password with valid recovery code", %{codes: codes} do
      conn =
        post(build_conn(), "/api/auth/reset-password", %{
          "username" => "resetuser",
          "recovery_code" => List.first(codes),
          "new_password" => "newpassword123"
        })

      assert json = json_response(conn, 200)
      assert json["success"] == true
    end

    test "fails with invalid credentials", %{codes: codes} do
      # Invalid code
      conn =
        post(build_conn(), "/api/auth/reset-password", %{
          "username" => "resetuser",
          "recovery_code" => "INVALIDCODE",
          "new_password" => "newpassword123"
        })

      assert json_response(conn, 422)["success"] == false

      # Non-existent user
      conn =
        post(build_conn(), "/api/auth/reset-password", %{
          "username" => "nonexistent",
          "recovery_code" => List.first(codes),
          "new_password" => "newpassword123"
        })

      assert json_response(conn, 422)["success"] == false
    end

    test "recovery code is consumed after use", %{codes: codes} do
      code = List.first(codes)

      params = %{
        "username" => "resetuser",
        "recovery_code" => code,
        "new_password" => "newpassword123"
      }

      # First reset succeeds
      assert json_response(post(build_conn(), "/api/auth/reset-password", params), 200)["success"]

      # Second reset with same code fails
      refute json_response(post(build_conn(), "/api/auth/reset-password", params), 422)["success"]
    end
  end

  describe "POST /api/auth/convert" do
    setup do
      conn = post(build_conn(), "/api/auth/anonymous")
      {:ok, conn: conn}
    end

    test "converts anonymous user to registered", %{conn: conn} do
      original_id = json_response(conn, 200)["data"]["user"]["id"]

      conn =
        post(conn, "/api/auth/convert", %{
          "username" => "converteduser",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["data"]["user"]["username"] == "converteduser"
      assert json["data"]["user"]["is_anonymous"] == false
      assert json["data"]["user"]["id"] == original_id
    end

    test "fails with invalid input", %{conn: conn} do
      # Passwords don't match
      conn =
        post(conn, "/api/auth/convert", %{
          "username" => "user1",
          "password" => "password123",
          "password_confirmation" => "different"
        })

      assert json_response(conn, 422)["success"] == false
    end

    test "fails when username is already taken", %{conn: conn} do
      post(build_conn(), "/api/auth/register", %{
        "username" => "takenname",
        "password" => "password123",
        "password_confirmation" => "password123"
      })

      conn =
        post(conn, "/api/auth/convert", %{
          "username" => "takenname",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      assert json_response(conn, 422)["success"] == false
    end

    test "requires authentication" do
      conn =
        post(build_conn(), "/api/auth/convert", %{
          "username" => "unauthuser",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      assert conn.status in [302, 401, 403]
    end

    test "fails for already registered users" do
      register_conn =
        post(build_conn(), "/api/auth/register", %{
          "username" => "alreadyregistered",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      register_conn =
        post(register_conn, "/api/auth/convert", %{
          "username" => "newname",
          "password" => "password123",
          "password_confirmation" => "password123"
        })

      assert json_response(register_conn, 422)["success"] == false
    end
  end
end
