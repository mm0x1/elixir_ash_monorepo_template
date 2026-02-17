defmodule TemplateApp.UserFixtures do
  @moduledoc """
  Test factories for User and related resources.

  Uses the domain's own functions as factories — no separate factory library needed.
  """

  alias TemplateApp.Domains.Accounts

  @doc """
  Creates a registered user. Accepts optional attrs to override defaults.

  Example:
      create_user()
      create_user(%{username: "alice", password: "supersecret123"})
  """
  def create_user(attrs \\ %{}) do
    username = Map.get(attrs, :username, "user#{System.unique_integer([:positive])}")
    password = Map.get(attrs, :password, "password123")

    {:ok, user} = Accounts.create_user(username, password, password)
    user
  end

  @doc """
  Creates an anonymous user.
  """
  def create_anonymous do
    {:ok, user} = Accounts.create_anonymous()
    user
  end

  @doc """
  Generates a valid JWT access token for the given user.
  """
  def access_token_for(user) do
    {:ok, token} = TemplateApp.Auth.JWT.generate_access_token(user)
    token
  end
end
