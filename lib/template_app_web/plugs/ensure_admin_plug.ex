defmodule TemplateAppWeb.Plugs.EnsureAdminPlug do
  @moduledoc """
  Ensures the current user has admin or superadmin role.

  For browser routes: Redirects to home page with error.
  For API routes: Returns 403 JSON response.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias TemplateAppWeb.Helpers.ConnHelpers

  def init(opts), do: opts

  def call(conn, _opts) do
    user = ConnHelpers.get_current_user(conn)

    if user && user.role in [:admin, :superadmin] do
      conn
    else
      if api_request?(conn) do
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden"})
        |> halt()
      else
        conn
        |> put_flash(:error, "You must be an administrator to access this page.")
        |> redirect(to: "/")
        |> halt()
      end
    end
  end

  defp api_request?(conn) do
    case get_req_header(conn, "accept") do
      [accept | _] -> String.contains?(accept, "application/json")
      _ -> false
    end
  end
end
