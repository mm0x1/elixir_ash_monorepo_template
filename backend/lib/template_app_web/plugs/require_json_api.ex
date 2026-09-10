defmodule TemplateAppWeb.Plugs.RequireJsonApi do
  @moduledoc """
  Requires JSON bodies for credential-bearing REST mutations.

  Bodyless auth operations such as refresh, logout, and recovery-code generation
  are deliberately not included in this boundary.
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @json_body_paths MapSet.new([
                     "/auth/login",
                     "/auth/register",
                     "/auth/reset-password",
                     "/account/username",
                     "/account/convert"
                   ])

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if requires_json?(conn) and not json_content_type?(conn) do
      conn
      |> put_status(:unsupported_media_type)
      |> json(%{
        error: "unsupported_media_type",
        message: "Credential-bearing requests must use application/json"
      })
      |> halt()
    else
      conn
    end
  end

  defp requires_json?(%Plug.Conn{method: method, request_path: path})
       when method in ["POST", "PUT", "PATCH"] do
    MapSet.member?(@json_body_paths, path)
  end

  defp requires_json?(_conn), do: false

  defp json_content_type?(conn) do
    case get_req_header(conn, "content-type") do
      [content_type | _] ->
        content_type
        |> String.split(";", parts: 2)
        |> hd()
        |> String.trim()
        |> String.downcase()
        |> then(&(&1 == "application/json" or String.ends_with?(&1, "+json")))

      [] ->
        false
    end
  end
end
