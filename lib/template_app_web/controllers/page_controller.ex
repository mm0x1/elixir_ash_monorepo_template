defmodule TemplateAppWeb.PageController do
  @moduledoc """
  Serves the application home page.
  """

  use TemplateAppWeb, :controller

  alias TemplateApp.Config

  require Logger

  def home(conn, _params) do
    conn
    |> assign_prop(:title, Config.app_name())
    |> render_inertia("Home")
  end
end
