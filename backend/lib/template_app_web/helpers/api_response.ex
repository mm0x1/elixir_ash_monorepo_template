defmodule TemplateAppWeb.Helpers.ApiResponse do
  @moduledoc """
  Centralised JSON response helpers for the REST controllers.

  Every controller response — success or error — flows through this module
  so the API speaks a single, consistent shape.
  """

  import Plug.Conn, only: [put_resp_header: 3, put_status: 2]
  import Phoenix.Controller, only: [json: 2]

  require Logger

  @safe_messages [
    "must match password",
    "does not match",
    "has already been taken",
    "must be 3-30 characters, letters, numbers, underscore only",
    "only anonymous users can convert to registered",
    "anonymous users cannot have recovery codes",
    "is required",
    "can't be blank",
    "is invalid"
  ]

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

  def validation_error(conn, error, _fallback_message) do
    case format_ash_errors(error) do
      {:ok, messages} ->
        conn
        |> put_status(422)
        |> no_store()
        |> json(%{
          error: "validation_error",
          message: List.first(messages),
          messages: messages
        })

      :error ->
        internal_error(conn, "validation_error")
    end
  end

  def internal_error(conn, _log_message) do
    Logger.error("Internal API error", error_category: "internal")

    conn
    |> put_status(500)
    |> no_store()
    |> json(%{error: "internal_error", message: "Something went wrong"})
  end

  defp no_store(conn), do: put_resp_header(conn, "cache-control", "no-store")

  # ── Error formatting ─────────────────────────────────────────────────

  defp format_ash_errors(%Ash.Error.Invalid{errors: errors}) when is_list(errors) do
    messages = Enum.map(errors, &safe_humanize_error/1)

    if Enum.all?(messages, &match?({:ok, _}, &1)) and messages != [] do
      {:ok, Enum.map(messages, fn {:ok, message} -> message end)}
    else
      :error
    end
  end

  defp format_ash_errors(_error), do: :error

  defp safe_humanize_error(error) do
    field = Map.get(error, :field)
    msg = Map.get(error, :message) || Exception.message(error)

    if safe_message?(msg) do
      if is_atom(field) do
        {:ok, "#{humanize_field(field)} #{msg}"}
      else
        {:ok, msg}
      end
    else
      :error
    end
  end

  defp safe_message?(message) when message in @safe_messages, do: true

  defp safe_message?(message) when is_binary(message) do
    Regex.match?(~r/\Amust be (?:at least|at most) \d+ characters\z/, message) or
      Regex.match?(~r/\Acan only be changed every \d+ days \(\d+ days remaining\)\z/, message)
  end

  defp safe_message?(_message), do: false

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
