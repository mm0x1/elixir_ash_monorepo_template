defmodule TemplateAppWeb.Helpers.ApiResponse do
  @moduledoc """
  Shared JSON error envelopes for the REST controllers.

  `AuthController` and `AccountController` return the same
  `%{error:, message:, errors:}` shapes for the common failure cases, so the
  envelope construction lives here once rather than being duplicated (and
  drifting) across both controllers.
  """

  import Plug.Conn, only: [put_status: 2]
  import Phoenix.Controller, only: [json: 2]
  import TemplateAppWeb.Helpers.UserSerializer, only: [format_ash_errors: 1]

  @doc """
  400 Bad Request — missing or malformed parameters.
  """
  def bad_request(conn, message) do
    conn
    |> put_status(400)
    |> json(%{error: "bad_request", message: message})
  end

  @doc """
  422 Unprocessable Entity — an Ash validation/changeset failure.
  """
  def validation_error(conn, error, message) do
    conn
    |> put_status(422)
    |> json(%{error: "validation_error", message: message, errors: format_ash_errors(error)})
  end

  @doc """
  403 Forbidden — an Ash policy denial.
  """
  def forbidden(conn, _error, message \\ "Not allowed") do
    conn
    |> put_status(403)
    |> json(%{error: "forbidden", message: message})
  end
end
