defmodule TemplateAppWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use TemplateAppWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint TemplateAppWeb.Endpoint

      use TemplateAppWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import TemplateAppWeb.ConnCase
    end
  end

  setup tags do
    TemplateApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Helper function to log in a user for controller tests.
  Sets up proper authentication using AshAuthentication.
  """
  def login_user(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> AshAuthentication.Plug.Helpers.store_in_session(user)
  end

  @doc """
  Helper function to add CSRF token to a connection.
  Generates a token and adds it to both the session and request headers.
  """
  def add_csrf_token(conn) do
    conn = Plug.Test.init_test_session(conn, %{})
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    Plug.Conn.put_req_header(conn, "x-csrf-token", csrf_token)
  end
end
