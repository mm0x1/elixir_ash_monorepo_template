defmodule TemplateApp.Auth.JWT do
  @moduledoc """
  JWT module for generating and verifying short-lived access tokens.

  Access tokens are stateless JWTs that:
  - Contain user_id and token_version
  - Expire after 15 minutes
  - Are verified by signature only (no database lookup)

  The token_version claim is checked against the user's current token_version
  to support "logout all devices" functionality.
  """

  use Joken.Config

  @access_token_lifetime_seconds 15 * 60

  @impl true
  def token_config do
    claims = default_claims(iss: "template_app", default_exp: @access_token_lifetime_seconds)

    claims
    |> add_claim("sub", nil, &is_binary/1)
    |> add_claim("token_version", nil, &is_integer/1)
  end

  @doc """
  Generates an access token for the given user.

  Returns {:ok, token} or {:error, reason}
  """
  @spec generate_access_token(user :: map()) :: {:ok, String.t()} | {:error, term()}
  def generate_access_token(user) do
    claims = %{
      "sub" => user.id,
      "token_version" => user.token_version
    }

    case generate_and_sign(claims, signer()) do
      {:ok, token, _claims} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Verifies an access token and returns the claims.

  Returns {:ok, claims} or {:error, reason}
  """
  @spec verify_access_token(token :: String.t()) :: {:ok, map()} | {:error, term()}
  def verify_access_token(token) do
    verify_and_validate(token, signer())
  end

  @doc """
  Returns the access token lifetime in seconds.
  """
  @spec access_token_lifetime :: non_neg_integer()
  def access_token_lifetime, do: @access_token_lifetime_seconds

  defp signer do
    Joken.Signer.create("HS256", signing_secret())
  end

  defp signing_secret do
    Application.fetch_env!(:template_app, :token_signing_secret)
  end
end
