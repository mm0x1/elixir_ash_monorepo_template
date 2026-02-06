defmodule TemplateAppWeb.Plugs.EnsureAdminPlug do
  @moduledoc """
  Ensures the current user has admin or superadmin role.
  Redirects to home page with an error message if not authorized.
  """
  import Plug.Conn
  import Phoenix.Controller
  import TemplateAppWeb.Helpers.InertiaHelpers, only: [error_flash: 2]

  alias TemplateAppWeb.Helpers.ConnHelpers

  def init(opts), do: opts

  def call(conn, _opts) do
    user = ConnHelpers.get_current_user(conn)

    if user && user.role in [:admin, :superadmin] do
      conn
    else
      conn
      |> error_flash("You must be an administrator to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
