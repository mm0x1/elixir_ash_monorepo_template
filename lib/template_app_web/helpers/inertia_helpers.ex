defmodule TemplateAppWeb.Helpers.InertiaHelpers do
  @moduledoc """
  Helpers for Inertia.js pages including flash messages and error handling.

  ## Flash Messages

  Flash messages are automatically passed to Inertia pages:

      conn |> error_flash("Invalid credentials")

  ## Error Bags

  Error bags allow multiple forms on a single page to have isolated validation errors:

      conn |> error_redirect_with_bag(error, bag: "login_form", to: "/auth")

  On the frontend, access errors via the bag name:

      const { errors } = usePage().props
      const loginErrors = errors?.login_form ?? {}
  """

  alias TemplateAppWeb.Helpers.ErrorFormatter

  @doc """
  Adds an error flash message to the connection.
  """
  def error_flash(%Plug.Conn{} = conn, message), do: add_flash(conn, :error, message)

  @doc """
  Adds an info flash message to the connection.
  """
  def info_flash(%Plug.Conn{} = conn, message), do: add_flash(conn, :info, message)

  @doc """
  Redirects with validation errors, optionally scoped to an error bag.

  When using error bags, errors are namespaced under the bag key,
  allowing multiple forms on a page to have isolated error state.

  ## Options

  - `:bag` - Optional error bag name (e.g., "login_form", "register_form")
  - `:to` - Redirect path (defaults to current request path)

  ## Examples

      # Without error bag (default behavior)
      error_redirect(conn, validation_error)

      # With error bag for multi-form pages
      error_redirect(conn, validation_error, bag: "login_form", to: "/auth")
  """
  def error_redirect(%Plug.Conn{} = conn, error, opts \\ []) do
    bag = Keyword.get(opts, :bag)
    to = Keyword.get(opts, :to, conn.request_path)

    {_status, errors} = ErrorFormatter.format_error_with_status(error)
    error_map = errors_to_map(errors)

    errors_prop =
      if bag do
        %{bag => error_map}
      else
        error_map
      end

    conn
    |> Inertia.Controller.assign_errors(errors_prop)
    |> Phoenix.Controller.redirect(to: to)
  end

  @doc """
  Assigns errors to the Inertia response with optional error bag support.

  Unlike `error_redirect/3`, this doesn't redirect and can be used
  for rendering the current page with errors.

  ## Options

  - `:bag` - Optional error bag name

  ## Example

      conn
      |> assign_errors(validation_error, bag: "contact_form")
      |> render_inertia("Contact")
  """
  def assign_errors(%Plug.Conn{} = conn, error, opts \\ []) do
    bag = Keyword.get(opts, :bag)

    {_status, errors} = ErrorFormatter.format_error_with_status(error)
    error_map = errors_to_map(errors)

    errors_prop =
      if bag do
        %{bag => error_map}
      else
        error_map
      end

    Inertia.Controller.assign_errors(conn, errors_prop)
  end

  # Private helpers

  defp add_flash(%Plug.Conn{} = conn, type, message) do
    conn
    |> Phoenix.Controller.put_flash(type, message)
    |> Inertia.Controller.assign_prop(:flash, %{Atom.to_string(type) => message})
  end

  defp errors_to_map(errors) when is_list(errors) do
    Enum.reduce(errors, %{}, fn
      %{field: field, message: msg}, acc when not is_nil(field) ->
        Map.put(acc, to_string(field), msg)

      %{message: msg}, acc ->
        Map.update(acc, "_form", msg, fn existing -> existing end)

      _, acc ->
        acc
    end)
  end

  defp errors_to_map(_), do: %{}
end
