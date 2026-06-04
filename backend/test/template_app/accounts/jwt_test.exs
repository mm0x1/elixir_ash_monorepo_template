defmodule TemplateApp.Accounts.JWTTest do
  use ExUnit.Case, async: true

  alias TemplateApp.Accounts.JWT

  @valid_user %{id: Ecto.UUID.generate(), token_version: 1}

  describe "generate_access_token/1 + verify_access_token/1" do
    test "round-trip produces correct claims" do
      {:ok, token} = JWT.generate_access_token(@valid_user)
      {:ok, claims} = JWT.verify_access_token(token)

      assert claims["sub"] == @valid_user.id
      assert claims["token_version"] == @valid_user.token_version
      assert claims["iss"] == "template_app"
    end

    test "token_version is preserved exactly" do
      user = %{id: Ecto.UUID.generate(), token_version: 42}
      {:ok, token} = JWT.generate_access_token(user)
      {:ok, claims} = JWT.verify_access_token(token)

      assert claims["token_version"] == 42
    end
  end

  describe "access_token_lifetime/0" do
    test "returns 900 seconds (15 minutes)" do
      assert JWT.access_token_lifetime() == 900
    end
  end

  describe "verify_access_token/1" do
    test "rejects a tampered token" do
      {:ok, token} = JWT.generate_access_token(@valid_user)
      tampered = token <> "x"

      assert {:error, _} = JWT.verify_access_token(tampered)
    end

    test "rejects a token signed with a different secret" do
      wrong_signer = Joken.Signer.create("HS256", "a_different_secret_key_for_testing_only")

      {:ok, bad_token, _} =
        Joken.encode_and_sign(
          %{"sub" => @valid_user.id, "token_version" => 1},
          wrong_signer
        )

      assert {:error, _} = JWT.verify_access_token(bad_token)
    end

    test "rejects garbage input" do
      assert {:error, _} = JWT.verify_access_token("not.a.token")
    end
  end
end
