defmodule TemplateAppWeb.AccountControllerTest do
  @moduledoc """
  Functional coverage for the token-gated account self-service endpoints added
  in Phase 5 (former RPC user ops re-expressed over REST):

  - `PATCH /account/username`
  - `POST  /account/recovery-codes`
  - `POST  /account/convert`

  Each endpoint is also exercised without a token to prove the deny-by-default
  gating enforced by `ValidateAccessToken`.
  """

  # async: false — the account ops are update actions running via Ash.bulk_update,
  # which spawn worker processes outside the sandbox ownership chain.
  use TemplateAppWeb.ConnCase, async: false

  import TemplateApp.UserFixtures

  alias TemplateApp.Accounts

  defp authenticate(conn, user) do
    put_req_header(conn, "authorization", "Bearer #{access_token_for(user)}")
  end

  # ---------------------------------------------------------------------------
  # PATCH /account/username
  # ---------------------------------------------------------------------------

  describe "PATCH /account/username" do
    test "changes the current user's username", %{conn: conn} do
      user = create_user(%{username: "oldname"})

      conn =
        conn
        |> authenticate(user)
        |> json_patch(~p"/account/username", %{username: "newname"})

      assert %{"user" => returned} = json_response(conn, 200)
      assert returned["username"] == "newname"
    end

    test "rejects a second change within the cooldown window with 422", %{conn: conn} do
      user = create_user(%{username: "cooldownuser"})

      first =
        conn
        |> authenticate(user)
        |> json_patch(~p"/account/username", %{username: "firstchange"})

      assert json_response(first, 200)

      second =
        build_conn()
        |> authenticate(user)
        |> json_patch(~p"/account/username", %{username: "secondchange"})

      assert %{"error" => "validation_error"} = json_response(second, 422)
    end

    test "returns 401 without a token", %{conn: conn} do
      conn = json_patch(conn, ~p"/account/username", %{username: "whatever"})

      assert %{"error" => "unauthorized"} = json_response(conn, 401)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /account/recovery-codes
  # ---------------------------------------------------------------------------

  describe "POST /account/recovery-codes" do
    test "returns plaintext codes once and persists only Argon2 hashes", %{conn: conn} do
      user = create_user(%{username: "codeowner"})

      conn =
        conn
        |> authenticate(user)
        |> post(~p"/account/recovery-codes")

      assert %{"recovery_codes" => plain_codes, "user" => _} = json_response(conn, 200)
      assert is_list(plain_codes)
      assert plain_codes != []

      {:ok, reloaded} = Accounts.get_by_username("codeowner")
      assert Enum.all?(reloaded.recovery_codes, &String.starts_with?(&1, "$argon2id$"))

      for plain <- plain_codes do
        refute plain in reloaded.recovery_codes
      end
    end

    test "returns 401 without a token", %{conn: conn} do
      conn = post(conn, ~p"/account/recovery-codes")

      assert %{"error" => "unauthorized"} = json_response(conn, 401)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /account/convert
  # ---------------------------------------------------------------------------

  describe "POST /account/convert" do
    test "converts an anonymous user into a registered one", %{conn: conn} do
      anon = create_anonymous()

      conn =
        conn
        |> authenticate(anon)
        |> json_post(~p"/account/convert", %{
          username: "nowregistered",
          password: "password123",
          password_confirmation: "password123"
        })

      assert %{"user" => returned} = json_response(conn, 200)
      assert returned["username"] == "nowregistered"
      assert returned["is_anonymous"] == false
    end

    test "rejects a non-anonymous user with 422", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> authenticate(user)
        |> json_post(~p"/account/convert", %{
          username: "alreadyregistered",
          password: "password123",
          password_confirmation: "password123"
        })

      assert %{"error" => "validation_error"} = json_response(conn, 422)
    end

    test "returns 401 without a token", %{conn: conn} do
      conn =
        json_post(conn, ~p"/account/convert", %{
          username: "whatever",
          password: "password123",
          password_confirmation: "password123"
        })

      assert %{"error" => "unauthorized"} = json_response(conn, 401)
    end
  end
end
