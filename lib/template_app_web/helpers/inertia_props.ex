defmodule TemplateAppWeb.Helpers.InertiaProps do
  @moduledoc """
  Helpers for Inertia.js lazy and deferred props.

  Inertia supports different loading strategies for props:

  - **Lazy**: Props that are deferred until a partial reload requests them
  - **Optional**: Props that are never sent by default, only when explicitly requested
  - **Always**: Props that are always included, even during partial reloads

  ## Usage

      def show(conn, _params) do
        conn
        |> assign_prop(:user, current_user)
        |> assign_prop(:stats, lazy(fn -> fetch_expensive_stats() end))
        |> assign_prop(:audit_log, optional(fn -> fetch_audit_log() end))
        |> assign_prop(:version, always("1.0.0"))
        |> render_inertia("Dashboard")
      end

  ## Frontend Usage

  Lazy props can be loaded on demand using Inertia's partial reload:

      router.reload({ only: ['stats'] })

  Optional props must be explicitly requested:

      router.reload({ only: ['audit_log'] })
  """

  @doc """
  Creates a lazy prop that defers loading until a partial reload requests it.

  The function will only be called when the prop is specifically requested
  via Inertia's partial reload mechanism.

  ## Example

      assign_prop(conn, :notifications, lazy(fn -> list_notifications(user_id) end))
  """
  def lazy(func) when is_function(func, 0) do
    %{__inertia_lazy__: true, loader: func}
  end

  @doc """
  Creates an optional prop that is never sent by default.

  Unlike lazy props, optional props are completely excluded from the initial
  page load and partial reloads unless explicitly requested with the 'only' parameter.

  ## Example

      assign_prop(conn, :detailed_metrics, optional(fn -> fetch_detailed_metrics() end))
  """
  def optional(func) when is_function(func, 0) do
    %{__inertia_optional__: true, loader: func}
  end

  @doc """
  Wraps a value to ensure it's always included in responses.

  This is useful for props that should never be excluded during partial reloads,
  such as CSRF tokens or essential configuration.

  ## Example

      assign_prop(conn, :csrf_token, always(get_csrf_token()))
  """
  def always(value) do
    %{__inertia_always__: true, value: value}
  end

  @doc """
  Resolves props, evaluating lazy/optional props based on the request context.

  This is called internally during Inertia response generation.

  ## Parameters

  - `props` - Map of props to resolve
  - `opts` - Options:
    - `:partial_data` - List of prop keys being requested in a partial reload
    - `:is_partial` - Whether this is a partial reload request

  ## Returns

  Resolved props map with lazy/optional functions evaluated as needed.
  """
  def resolve_props(props, opts \\ []) do
    partial_data = Keyword.get(opts, :partial_data, [])
    is_partial = Keyword.get(opts, :is_partial, false)

    Enum.reduce(props, %{}, fn {key, value}, acc ->
      resolved = resolve_prop(key, value, partial_data, is_partial)

      case resolved do
        :skip -> acc
        {:ok, val} -> Map.put(acc, key, val)
      end
    end)
  end

  defp resolve_prop(key, %{__inertia_lazy__: true, loader: func}, partial_data, is_partial) do
    key_str = to_string(key)

    if is_partial and key_str in partial_data do
      {:ok, func.()}
    else
      if is_partial do
        :skip
      else
        # On initial load, evaluate lazy props
        {:ok, func.()}
      end
    end
  end

  defp resolve_prop(key, %{__inertia_optional__: true, loader: func}, partial_data, _is_partial) do
    key_str = to_string(key)

    if key_str in partial_data do
      {:ok, func.()}
    else
      :skip
    end
  end

  defp resolve_prop(_key, %{__inertia_always__: true, value: value}, _partial_data, _is_partial) do
    {:ok, value}
  end

  defp resolve_prop(_key, value, _partial_data, _is_partial) do
    {:ok, value}
  end
end
