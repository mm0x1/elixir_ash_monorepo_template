defmodule TemplateAppWeb.FrontendController do
  @moduledoc """
  Serves the built SPA fallback in the combined production release.
  """

  use TemplateAppWeb, :controller

  def index(conn, %{"path" => path}) when is_list(path) do
    if Enum.any?(path, &String.contains?(&1, ".")) do
      send_resp(conn, 404, "Not Found")
    else
      serve_index(conn)
    end
  end

  def index(conn, _params), do: serve_index(conn)

  defp serve_index(conn) do
    # The release path is fixed; wildcard input only selects fallback vs 404.
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, Application.app_dir(:template_app, "priv/static/index.html"))
  end
end
