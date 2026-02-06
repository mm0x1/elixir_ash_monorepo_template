defmodule TemplateAppWeb.Plugs.EnsureAuthenticatedPlug do
  @moduledoc """
  Ensures the user is authenticated before allowing access to a route.
  """
  import Plug.Conn
  import Phoenix.Controller
  import TemplateAppWeb.Helpers.InertiaHelpers, only: [error_flash: 2]

  alias TemplateAppWeb.Helpers.ConnHelpers

  def init(opts), do: opts

  def call(conn, _opts) do
    if ConnHelpers.get_current_user(conn) do
      conn
    else
      conn
      |> error_flash("You must be signed in to access this page.")
      |> redirect(to: "/auth/sign-in")
      |> halt()
    end
  end
end
