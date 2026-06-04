defmodule TemplateAppWeb.Plugs.ValidateAccessTokenTest do
  use TemplateAppWeb.ConnCase, async: true

  import TemplateApp.UserFixtures

  alias TemplateAppWeb.Plugs.ValidateAccessToken
  alias TemplateApp.Accounts.JWT

  defp call_plug(conn) do
    ValidateAccessToken.call(conn, ValidateAccessToken.init([]))
  end

  defp with_bearer(conn, token) do
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

  describe "missing or malformed Authorization header" do
    test "returns 401 when header is absent", %{conn: conn} do
      conn = call_plug(conn)

      assert conn.status == 401
      assert conn.halted
      assert %{"error" => "unauthorized"} = json_response(conn, 401)
    end

    test "returns 401 for garbage token", %{conn: conn} do
      conn = conn |> with_bearer("not.a.jwt") |> call_plug()

      assert conn.status == 401
      assert conn.halted
    end
  end

  describe "valid token" do
    test "assigns current_user and does not halt", %{conn: conn} do
      user = create_user()
      {:ok, token} = JWT.generate_access_token(user)

      conn = conn |> with_bearer(token) |> call_plug()

      refute conn.halted
      assert conn.assigns.current_user.id == user.id
    end
  end

  describe "token version mismatch (logout all)" do
    test "returns 401 with revoked message after token_version increment", %{conn: conn} do
      user = create_user()
      {:ok, token} = JWT.generate_access_token(user)

      # Simulate logout_all by incrementing token_version
      {:ok, _} = Ash.update(user, %{}, action: :increment_token_version, actor: user)

      conn = conn |> with_bearer(token) |> call_plug()

      assert conn.status == 401
      assert conn.halted
      assert %{"message" => "Token has been revoked"} = json_response(conn, 401)
    end
  end

  describe "token for non-existent user" do
    test "returns 401 for a token with a fabricated unknown user ID", %{conn: conn} do
      # Build a token that references a user UUID that doesn't exist in the DB
      ghost_user = %{id: Ecto.UUID.generate(), token_version: 1}
      {:ok, token} = JWT.generate_access_token(ghost_user)

      conn = conn |> with_bearer(token) |> call_plug()

      assert conn.status == 401
      assert conn.halted
    end
  end
end
