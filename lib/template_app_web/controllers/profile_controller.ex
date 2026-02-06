defmodule TemplateAppWeb.ProfileController do
  @moduledoc """
  Renders Inertia.js pages for profile views.
  Business logic handled by API controllers.
  """

  use TemplateAppWeb, :controller

  def show_profile(conn, _params) do
    conn
    |> assign_prop(:title, "Profile")
    |> render_inertia("UserProfile")
  end
end
