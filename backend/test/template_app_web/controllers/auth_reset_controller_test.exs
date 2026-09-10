defmodule TemplateAppWeb.AuthResetControllerTest do
  @moduledoc """
  Functional coverage for the pre-issued recovery-code password-reset flow.

  Exercises the real controllers and real Ash actions against the sandbox DB.
  """

  # async: false — reset_password drives an update action that runs via
  # Ash.bulk_update, spawning worker processes outside the sandbox ownership
  # chain. Shared sandbox mode lets those processes see the test's data.
  use TemplateAppWeb.ConnCase, async: false

  import TemplateApp.UserFixtures

  alias TemplateApp.Accounts
  alias TemplateApp.Accounts.Resources.RefreshToken

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

  defp with_refresh_cookie(token_id) do
    Plug.Test.put_req_cookie(build_conn(), "_template_app_refresh", token_id)
  end

  # ---------------------------------------------------------------------------
  # POST /auth/reset-password
  # ---------------------------------------------------------------------------

  describe "POST /auth/reset-password" do
    test "valid code resets the password: new password logs in, old one 401s", %{conn: conn} do
      {_user, [code | _]} = create_user_with_recovery_codes(%{username: "switcher"})

      reset_conn =
        post(conn, ~p"/auth/reset-password", %{
          username: "switcher",
          recovery_code: code,
          new_password: "brandnewpassword"
        })

      assert %{"message" => _} = json_response(reset_conn, 200)

      # New password now authenticates.
      new_login =
        post(build_conn(), ~p"/auth/login", %{username: "switcher", password: "brandnewpassword"})

      assert %{"access_token" => _} = json_response(new_login, 200)

      # Old password no longer works.
      old_login =
        post(build_conn(), ~p"/auth/login", %{username: "switcher", password: "password123"})

      assert %{"error" => "invalid_credentials"} = json_response(old_login, 401)
    end

    test "invalidates the access token and refresh sessions created before reset", %{
      conn: conn
    } do
      {user, [code | _]} = create_user_with_recovery_codes(%{username: "sessionreset"})
      access_token = access_token_for(user)
      refresh_token = create_refresh_token(user)

      reset_conn =
        post(conn, ~p"/auth/reset-password", %{
          username: "sessionreset",
          recovery_code: code,
          new_password: "brandnewpassword"
        })

      assert %{"message" => _} = json_response(reset_conn, 200)

      me_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> get(~p"/auth/me")

      assert %{"error" => "unauthorized"} = json_response(me_conn, 401)

      refresh_conn = post(with_refresh_cookie(refresh_token.id), ~p"/auth/refresh")
      assert %{"error" => "invalid_refresh_token"} = json_response(refresh_conn, 401)

      {:ok, updated_user} = Accounts.get_user_by_id(user.id)
      assert updated_user.token_version == user.token_version + 1
    end

    test "returns 422 when a code is reused", %{conn: conn} do
      {_user, [code | _]} = create_user_with_recovery_codes(%{username: "reuser"})

      first =
        post(conn, ~p"/auth/reset-password", %{
          username: "reuser",
          recovery_code: code,
          new_password: "firstnewpassword"
        })

      assert json_response(first, 200)

      second =
        post(build_conn(), ~p"/auth/reset-password", %{
          username: "reuser",
          recovery_code: code,
          new_password: "secondnewpassword"
        })

      assert %{"error" => "validation_error", "message" => "Invalid recovery code"} =
               json_response(second, 422)
    end

    test "returns 422 when the recovery-code batch has expired", %{conn: conn} do
      {user, [code | _]} = create_user_with_recovery_codes(%{username: "expired"})
      expire_recovery_codes(user)

      conn =
        post(conn, ~p"/auth/reset-password", %{
          username: "expired",
          recovery_code: code,
          new_password: "newpassword123"
        })

      assert %{"error" => "validation_error", "message" => "Invalid recovery code"} =
               json_response(conn, 422)
    end

    test "returns a generic error for an anonymous username", %{conn: conn} do
      user = create_anonymous()

      conn =
        post(conn, ~p"/auth/reset-password", %{
          username: to_string(user.username),
          recovery_code: "ABC123",
          new_password: "newpassword123"
        })

      assert %{"error" => "validation_error", "message" => "Invalid recovery code"} =
               json_response(conn, 422)
    end

    test "returns generic validation error for an unknown username (anti-enumeration)", %{
      conn: conn
    } do
      conn =
        post(conn, ~p"/auth/reset-password", %{
          username: "ghost",
          recovery_code: "ABC123",
          new_password: "newpassword123"
        })

      assert %{"error" => "validation_error", "message" => "Invalid recovery code"} =
               json_response(conn, 422)
    end

    test "returns 400 when params are missing", %{conn: conn} do
      conn = post(conn, ~p"/auth/reset-password", %{username: "incomplete"})

      assert %{"error" => "bad_request"} = json_response(conn, 400)
    end
  end
end
