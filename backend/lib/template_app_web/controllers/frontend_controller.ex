defmodule TemplateAppWeb.FrontendController do
  @moduledoc """
  Serves the built SPA fallback in the combined production release.
  """

  use TemplateAppWeb, :controller

  @inline_script ~r/<script(?:\s[^>]*)?>(.*?)<\/script>/s

  def index(conn, %{"path" => path}) when is_list(path) do
    if Enum.any?(path, &String.contains?(&1, ".")) do
      send_resp(conn, 404, "Not Found")
    else
      serve_index(conn)
    end
  end

  def index(conn, _params), do: serve_index(conn)

  @doc false
  def content_security_policy(html) when is_binary(html) do
    inline_scripts = Regex.scan(@inline_script, html, capture: :all_but_first)

    script_sources =
      inline_scripts
      |> Enum.map(fn [script] -> "'sha256-#{hash(script)}'" end)
      |> Enum.uniq()
      |> then(&["'self'" | &1])
      |> Enum.join(" ")

    "default-src 'self'; " <>
      "script-src #{script_sources}; " <>
      "style-src 'self'; " <>
      "img-src 'self' data: https:; " <>
      "font-src 'self' data:; " <>
      "connect-src #{connect_src_policy()}; " <>
      "object-src 'none'; " <>
      "frame-ancestors 'none'; " <>
      "base-uri 'self'; " <>
      "form-action 'self';"
  end

  defp serve_index(conn) do
    index_path = Application.app_dir(:template_app, "priv/static/index.html")

    case File.read(index_path) do
      {:ok, html} ->
        conn
        |> put_resp_content_type("text/html")
        |> Plug.Conn.put_resp_header("content-security-policy", content_security_policy(html))
        |> send_resp(200, html)

      {:error, _reason} ->
        send_resp(conn, 500, "Frontend unavailable")
    end
  end

  defp hash(script) do
    Base.encode64(:crypto.hash(:sha256, script))
  end

  defp connect_src_policy do
    ["'self'", Application.get_env(:template_app, :api_origin)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end
end
