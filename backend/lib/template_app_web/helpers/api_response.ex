defmodule TemplateAppWeb.Helpers.ApiResponse do
  @moduledoc """
  Centralised JSON response helpers for the REST controllers.

  Every controller response — success or error — flows through this module
  so the API speaks a single, consistent shape.
  """

  import Plug.Conn, only: [put_resp_header: 3, put_status: 2]
  import Phoenix.Controller, only: [json: 2]

  require Logger

  # ── Success helpers ──────────────────────────────────────────────────

  def success(conn, data), do: conn |> no_store() |> json(data)

  def success(conn, data, status) do
    conn
    |> put_status(status)
    |> no_store()
    |> json(data)
  end

  def message(conn, message), do: conn |> no_store() |> json(%{message: message})

  # ── Error helpers ────────────────────────────────────────────────────

  def bad_request(conn, message) do
    conn
    |> put_status(400)
    |> no_store()
    |> json(%{error: "bad_request", message: message})
  end

  def unauthorized(conn, code, message) do
    conn
    |> put_status(401)
    |> no_store()
    |> json(%{error: code, message: message})
  end

  def forbidden(conn, _error, message \\ "Not allowed") do
    conn
    |> put_status(403)
    |> no_store()
    |> json(%{error: "forbidden", message: message})
  end

  def not_found(conn, message) do
    conn
    |> put_status(404)
    |> no_store()
    |> json(%{error: "not_found", message: message})
  end

  def validation_error_static(conn, message) do
    conn
    |> put_status(422)
    |> no_store()
    |> json(%{error: "validation_error", message: message, messages: [message]})
  end

  def validation_error(conn, error, fallback_message) do
    messages = format_ash_errors(error)

    conn
    |> put_status(422)
    |> no_store()
    |> json(%{
      error: "validation_error",
      message: List.first(messages) || fallback_message,
      messages: messages
    })
  end

  def internal_error(conn, log_message) do
    Logger.error(log_message)

    conn
    |> put_status(500)
    |> no_store()
    |> json(%{error: "internal_error", message: "Something went wrong"})
  end

  defp no_store(conn), do: put_resp_header(conn, "cache-control", "no-store")

  # ── Error formatting ─────────────────────────────────────────────────

  defp format_ash_errors(%Ash.Error.Invalid{errors: errors}) do
    Enum.map(errors, &humanize_error/1)
  end

  defp format_ash_errors(error) do
    [Exception.message(error)]
  end

  defp humanize_error(error) do
    field = Map.get(error, :field)
    msg = Exception.message(error)

    if field do
      "#{humanize_field(field)} #{msg}"
    else
      msg
    end
  end

  defp humanize_field(field) when is_atom(field) do
    field
    |> Atom.to_string()
    |> humanize_field()
  end

  defp humanize_field(field) when is_binary(field) do
    field
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
