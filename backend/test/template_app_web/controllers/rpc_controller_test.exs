defmodule TemplateAppWeb.RpcControllerTest do
  # async: false required because ash_typescript dispatches update actions via Ash.bulk_update,
  # which spawns worker processes outside the sandbox ownership chain.
  # Shared sandbox mode (async: false) lets all spawned processes access test data.
  use TemplateAppWeb.ConnCase, async: false

  import TemplateApp.UserFixtures

  # Mirrors USER_FIELDS in frontend/src/lib/api/accounts.ts.
  # If you add a field there, add it here too.
  @user_fields ~w[id username is_anonymous role has_recovery_codes recovery_codes_count]

  # ---------------------------------------------------------------------------
  # Shared helpers
  # ---------------------------------------------------------------------------

  defp rpc(conn, params) do
    post(conn, ~p"/rpc/run", params)
  end

  defp authenticate(conn, user) do
    put_req_header(conn, "authorization", "Bearer #{access_token_for(user)}")
  end

  # Asserts the RPC success envelope and returns `data` for further assertions.
  defp assert_rpc_success(conn) do
    assert %{"success" => true, "data" => data} = json_response(conn, 200)
    data
  end

  # Asserts the RPC failure envelope and returns the errors list.
  defp assert_rpc_failure(conn) do
    assert %{"success" => false, "errors" => errors} = json_response(conn, 200)
    assert is_list(errors) and length(errors) > 0
    errors
  end

  # Asserts the shape of a returned user object and that no denied fields leaked.
  defp assert_user_shape(data) do
    assert is_binary(data["id"])
    assert is_binary(data["username"])
    assert is_boolean(data["is_anonymous"])
    assert data["role"] in ~w[user admin superadmin]
    assert is_boolean(data["has_recovery_codes"])
    assert is_integer(data["recovery_codes_count"])

    # These fields are always denied — they must never appear in any response.
    refute Map.has_key?(data, "hashed_password")
    refute Map.has_key?(data, "recovery_codes_generated_at")
    refute Map.has_key?(data, "username_last_changed")
  end

  # ---------------------------------------------------------------------------
  # Auth barrier
  # ---------------------------------------------------------------------------

  describe "POST /rpc/run (auth barrier)" do
    test "returns 401 without a Bearer token", %{conn: conn} do
      conn = rpc(conn, %{action: "get_user", input: %{id: Ecto.UUID.generate()}, fields: @user_fields})

      assert json_response(conn, 401)
    end

    test "returns 401 with a malformed token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer not_a_real_token")
        |> rpc(%{action: "get_user", input: %{id: Ecto.UUID.generate()}, fields: @user_fields})

      assert json_response(conn, 401)
    end
  end

  # ---------------------------------------------------------------------------
  # get_user
  # ---------------------------------------------------------------------------

  describe "get_user" do
    test "returns user with all expected fields", %{conn: conn} do
      user = create_user()

      data =
        conn
        |> authenticate(user)
        |> rpc(%{action: "get_user", input: %{id: user.id}, fields: @user_fields})
        |> assert_rpc_success()

      assert_user_shape(data)
      assert data["id"] == user.id
      assert data["is_anonymous"] == false
    end

    test "returns failure envelope for a non-existent id", %{conn: conn} do
      user = create_user()

      conn
      |> authenticate(user)
      |> rpc(%{action: "get_user", input: %{id: Ecto.UUID.generate()}, fields: @user_fields})
      |> assert_rpc_failure()
    end
  end

  # ---------------------------------------------------------------------------
  # change_username
  # ---------------------------------------------------------------------------

  describe "change_username" do
    test "updates username and returns the updated user", %{conn: conn} do
      user = create_user()
      new_name = "changed_#{System.unique_integer([:positive])}"

      data =
        conn
        |> authenticate(user)
        |> rpc(%{
          action: "change_username",
          identity: user.id,
          input: %{username: new_name},
          fields: @user_fields
        })
        |> assert_rpc_success()

      assert_user_shape(data)
      assert data["username"] == new_name
    end

    test "returns failure envelope when username is already taken", %{conn: conn} do
      user = create_user()
      other = create_user()

      conn
      |> authenticate(user)
      |> rpc(%{
        action: "change_username",
        identity: user.id,
        input: %{username: other.username},
        fields: @user_fields
      })
      |> assert_rpc_failure()
    end
  end

  # ---------------------------------------------------------------------------
  # generate_recovery_codes
  # ---------------------------------------------------------------------------

  describe "generate_recovery_codes" do
    test "returns updated user status and plain codes in top-level metadata", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> authenticate(user)
        |> rpc(%{action: "generate_recovery_codes", identity: user.id, fields: @user_fields})

      response = json_response(conn, 200)
      assert %{"success" => true, "data" => data, "metadata" => metadata} = response

      assert_user_shape(data)
      assert data["has_recovery_codes"] == true
      assert data["recovery_codes_count"] > 0

      # Plain codes are delivered once in response["metadata"] (top-level, not inside data).
      # The frontend must read result.metadata.plain_recovery_codes, not result.data.__metadata__.
      assert %{"plain_recovery_codes" => codes} = metadata
      assert length(codes) > 0
      assert Enum.all?(codes, &is_binary/1)
    end

    test "does not expose raw hashed recovery_codes when not requested in fields", %{conn: conn} do
      user = create_user()

      data =
        conn
        |> authenticate(user)
        |> rpc(%{action: "generate_recovery_codes", identity: user.id, fields: @user_fields})
        |> assert_rpc_success()

      refute Map.has_key?(data, "recovery_codes")
    end
  end

  # ---------------------------------------------------------------------------
  # convert_to_registered
  # ---------------------------------------------------------------------------

  describe "convert_to_registered" do
    test "converts an anonymous user and returns the registered user", %{conn: conn} do
      anon = create_anonymous()
      username = "reg_#{System.unique_integer([:positive])}"

      data =
        conn
        |> authenticate(anon)
        |> rpc(%{
          action: "convert_to_registered",
          identity: anon.id,
          input: %{
            username: username,
            password: "password123",
            password_confirmation: "password123"
          },
          fields: @user_fields
        })
        |> assert_rpc_success()

      assert_user_shape(data)
      assert data["username"] == username
      assert data["is_anonymous"] == false
    end

    test "returns failure envelope when called on an already-registered user", %{conn: conn} do
      user = create_user()

      conn
      |> authenticate(user)
      |> rpc(%{
        action: "convert_to_registered",
        identity: user.id,
        input: %{
          username: "wontwork",
          password: "password123",
          password_confirmation: "password123"
        },
        fields: @user_fields
      })
      |> assert_rpc_failure()
    end
  end
end
