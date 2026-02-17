defmodule TemplateAppWeb.Helpers.ErrorFormatter do
  @moduledoc """
  Centralized error formatting for API responses.

  Converts Ash errors into clean, client-friendly error messages without
  internal debugging information like breadcrumbs or stack traces.

  ## Usage

      # In controllers
      {:error, error} ->
        {status, formatted_errors} = ErrorFormatter.format_error_with_status(error)

        conn
        |> put_status(status)
        |> json(%{success: false, errors: formatted_errors})

  ## Error Format

  Field validation errors:
      [%{field: "password", message: "length must be greater than or equal to 8"}]

  General errors:
      [%{message: "User not found"}]

  Server errors (production):
      %{error_id: "550e8400-e29b-41d4-a716-446655440000", message: "Something went wrong. Please try again."}

  ## Environment Awareness

  In development, full error details are returned for debugging.
  In production, server errors are sanitized and an error_id is provided for correlation.
  """

  require Logger

  @doc """
  Formats an error and returns both HTTP status code and formatted error list.

  Returns `{status_code, error_list}` where:
  - status_code: Integer HTTP status (422, 403, 404, 500, etc.)
  - error_list: List of error maps with :message and optionally :field keys

  ## Examples

      iex> format_error_with_status(%Ash.Error.Invalid{})
      {422, [%{field: "email", message: "is required"}]}

      iex> format_error_with_status(%Ash.Error.Forbidden{})
      {403, [%{message: "Forbidden"}]}
  """
  def format_error_with_status(error) do
    status = error_to_status(error)
    formatted = format_error(error)
    {status, formatted}
  end

  @doc """
  Formats an error for API response with environment awareness.

  In development: Returns full error details for debugging
  In production: Returns sanitized errors with error_id for non-validation errors

  ## Examples

      # Validation error - same in both environments
      iex> format_error_for_response(%Ash.Error.Invalid{})
      {422, [%{field: "email", message: "is required"}]}

      # Server error in production
      iex> format_error_for_response(%RuntimeError{})
      {500, %{error_id: "uuid", message: "Something went wrong. Please try again."}}

      # Server error in development - full details
      iex> format_error_for_response(%RuntimeError{message: "DB connection failed"})
      {500, [%{message: "DB connection failed"}]}
  """
  def format_error_for_response(error) do
    if production?() do
      sanitize_for_prod(error)
    else
      format_error_with_status(error)
    end
  end

  @doc """
  Formats a server error with UUID for correlation in logs.

  Logs the full error with error_id, returns sanitized response for clients.

  ## Example

      iex> format_server_error(%RuntimeError{message: "connection failed"})
      %{error_id: "550e8400-...", message: "Something went wrong. Please try again."}
  """
  def format_server_error(error) do
    error_id = generate_error_id()

    Logger.error("Server error occurred",
      error_id: error_id,
      error: inspect(error),
      error_type: error.__struct__
    )

    %{error_id: error_id, message: "Something went wrong. Please try again."}
  end

  @doc """
  Generates a UUID v4 for error correlation.
  """
  def generate_error_id do
    Ash.UUID.generate()
  end

  @doc """
  Formats an error into a clean, client-friendly error list.

  Returns a list of error maps, each containing:
  - :message - Clean error message without breadcrumbs
  - :field - (optional) The field name for validation errors

  ## Examples

      iex> format_error(%Ash.Error.Invalid{errors: [...]})
      [%{field: "password", message: "length must be greater than or equal to 8"}]

      iex> format_error(%RuntimeError{message: "Something went wrong"})
      [%{message: "Something went wrong"}]
  """
  def format_error(error)

  # Ash validation errors - extract clean field-specific messages
  def format_error(%Ash.Error.Invalid{errors: errors}) when is_list(errors) do
    errors
    |> Enum.map(&extract_clean_error/1)
    |> Enum.reject(&is_nil/1)
  end

  # Ash forbidden errors
  def format_error(%Ash.Error.Forbidden{} = error) do
    [%{message: extract_message(error) || "Forbidden"}]
  end

  # Ash not found errors
  def format_error(%Ash.Error.Query.NotFound{} = error) do
    [%{message: extract_message(error) || "Resource not found"}]
  end

  # Generic exception with message
  def format_error(%{__exception__: true} = error) when is_exception(error) do
    [%{message: Exception.message(error)}]
  end

  # Fallback for unknown error types
  def format_error(error) do
    [%{message: "An error occurred: #{inspect(error)}"}]
  end

  # Private functions

  @doc false
  defp production? do
    Application.get_env(:template_app, :env, :dev) == :prod
  end

  @doc false
  defp sanitize_for_prod(%Ash.Error.Invalid{} = error) do
    # Validation errors are safe to return - just clean field/message pairs
    {status, errors} = format_error_with_status(error)
    sanitized = Enum.map(errors, &Map.take(&1, [:field, :message]))
    {status, sanitized}
  end

  defp sanitize_for_prod(%Ash.Error.Forbidden{}) do
    {403, [%{message: "Forbidden"}]}
  end

  defp sanitize_for_prod(%Ash.Error.Query.NotFound{}) do
    {404, [%{message: "Not found"}]}
  end

  defp sanitize_for_prod(error) do
    # Server errors get a UUID and generic message in production
    {500, format_server_error(error)}
  end

  @doc false
  defp extract_clean_error(error) do
    case error do
      # Invalid attribute errors (most common validation errors)
      %Ash.Error.Changes.InvalidAttribute{field: field} = err ->
        %{
          field: field,
          message: clean_message(err)
        }

      # Invalid argument errors (action argument validation)
      %Ash.Error.Changes.InvalidArgument{field: field} = err ->
        %{
          field: field,
          message: clean_message(err)
        }

      # Required field errors
      %Ash.Error.Changes.Required{field: field, type: type} ->
        %{
          field: field,
          message: "#{type || "field"} is required"
        }

      # Generic error with field
      %{field: field} = err when not is_nil(field) ->
        %{
          field: field,
          message: clean_message(err)
        }

      # Generic error without field
      _ ->
        message = clean_message(error)

        if message && message != "" do
          %{message: message}
        else
          nil
        end
    end
  end

  @doc false
  defp extract_message(error) do
    cond do
      # Check if error has a message field directly
      Map.has_key?(error, :message) ->
        error.message

      # Check if it's an exception
      is_exception(error) ->
        Exception.message(error)

      # Fallback
      true ->
        nil
    end
  end

  @doc false
  # Handle error structs with vars for message interpolation
  defp clean_message(%{message: message, vars: vars}) when is_binary(message) and is_list(vars) do
    # Interpolate message template with vars (e.g., %{min} → 8)
    interpolated =
      Enum.reduce(vars, message, fn {key, value}, acc ->
        placeholder = "%{#{key}}"

        if String.contains?(acc, placeholder) do
          String.replace(acc, placeholder, to_string(value))
        else
          acc
        end
      end)

    # Then clean breadcrumbs
    clean_string_message(interpolated)
  end

  # Handle error structs without vars
  defp clean_message(%{message: message}) when is_binary(message) do
    clean_string_message(message)
  end

  # Handle plain string messages
  defp clean_message(message) when is_binary(message) do
    clean_string_message(message)
  end

  # Fallback
  defp clean_message(message), do: to_string(message)

  @doc false
  defp clean_string_message(message) when is_binary(message) do
    message
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&String.starts_with?(&1, "Bread Crumbs:"))
    |> Enum.reject(&String.starts_with?(&1, ">"))
    |> Enum.find(&(&1 != ""))
    |> case do
      nil -> message
      clean -> clean
    end
  end

  @doc false
  defp error_to_status(error) do
    cond do
      # Check for authentication failures (should be 401, not 403)
      authentication_failure?(error) -> 401
      # Standard Ash error mappings
      match?(%Ash.Error.Invalid{}, error) -> 422
      match?(%Ash.Error.Forbidden{}, error) -> 403
      match?(%Ash.Error.Query.NotFound{}, error) -> 404
      match?(%Ash.Error.Unknown{}, error) -> 500
      match?(%Ash.Error.Framework{}, error) -> 500
      true -> 500
    end
  end

  # Detect authentication failures (wrong credentials) nested within Forbidden errors.
  # AshAuthentication wraps credential failures as :forbidden class errors, but HTTP
  # convention is 401 (unauthenticated) rather than 403 (unauthorised) for bad credentials.
  defp authentication_failure?(%Ash.Error.Forbidden{errors: errors}) when is_list(errors) do
    Enum.any?(errors, &authentication_failure?/1)
  end

  defp authentication_failure?(%{class: :forbidden} = error) do
    error.__struct__
    |> Module.split()
    |> List.starts_with?(["AshAuthentication"])
  end

  defp authentication_failure?(_), do: false
end
