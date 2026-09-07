defmodule TemplateAppWeb.Plugs.EnsureAuthenticatedPlug do
  @moduledoc """
  Ensures the user is authenticated before allowing access to a route.

  For browser routes: Redirects to sign-in page.
  For API routes: Returns 401 JSON response.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias TemplateAppWeb.Helpers.ConnHelpers

  def init(opts), do: opts

  def call(conn, _opts) do
    if ConnHelpers.get_current_user(conn) do
      conn
    else
      if api_request?(conn) do
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
        |> halt()
      else
        conn
        |> put_flash(:error, "You must be signed in to access this page.")
        |> redirect(to: "/dev/admin/sign-in")
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
