defmodule TemplateAppWeb.Helpers.PaginationHelpers do
  @moduledoc """
  Helpers for creating consistent pagination responses.

  Creates a standardized pagination response format that matches
  the frontend's expected data contract.

  ## Response Format

      %{
        data: [...],
        meta: %{
          offset: 0,
          limit: 20,
          count: 150,
          has_more: true
        }
      }

  ## Usage with Ash

      def index(conn, params) do
        case Accounts.list_users(page: [offset: offset, limit: limit]) do
          {:ok, page} ->
            json(conn, paginated_response(page, &UserSerializer.serialize/1))

          {:error, error} ->
            # handle error
        end
      end

  ## Usage with Custom Data

      paginated_response(
        items,
        &transform/1,
        offset: 0,
        limit: 20,
        count: 100
      )
  """

  @doc """
  Creates a paginated response from an Ash page result.

  ## Parameters

  - `page` - Ash page result (struct with `results`, `offset`, `limit`, `count`, `more?`)
  - `serializer` - Function to transform each item (receives item, returns serialized value)

  ## Returns

  Map with `:data` and `:meta` keys matching the standard pagination contract.

  ## Example

      paginated_response(page, &UserSerializer.serialize/1)
      # => %{data: [...], meta: %{offset: 0, limit: 20, count: 150, has_more: true}}
  """
  def paginated_response(%{results: results} = page, serializer)
      when is_function(serializer, 1) do
    %{
      data: Enum.map(results, serializer),
      meta: %{
        offset: page.offset || 0,
        limit: page.limit || length(results),
        count: page.count || length(results),
        has_more: page.more? || false
      }
    }
  end

  @doc """
  Creates a paginated response from a list with explicit pagination info.

  ## Parameters

  - `items` - List of items to paginate
  - `serializer` - Function to transform each item
  - `opts` - Pagination options:
    - `:offset` - Current offset (default: 0)
    - `:limit` - Items per page (default: length of items)
    - `:count` - Total count of items (default: length of items)

  ## Example

      paginated_response(
        users,
        &UserSerializer.serialize/1,
        offset: 20,
        limit: 20,
        count: 150
      )
  """
  def paginated_response(items, serializer, opts)
      when is_list(items) and is_function(serializer, 1) do
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit, length(items))
    count = Keyword.get(opts, :count, length(items))
    has_more = offset + length(items) < count

    %{
      data: Enum.map(items, serializer),
      meta: %{
        offset: offset,
        limit: limit,
        count: count,
        has_more: has_more
      }
    }
  end

  @doc """
  Creates empty pagination response.

  Useful for when there are no results.

  ## Example

      empty_response()
      # => %{data: [], meta: %{offset: 0, limit: 0, count: 0, has_more: false}}
  """
  def empty_response do
    %{
      data: [],
      meta: %{
        offset: 0,
        limit: 0,
        count: 0,
        has_more: false
      }
    }
  end

  @doc """
  Extracts pagination parameters from request params.

  Safely parses and validates pagination params with defaults.

  ## Parameters

  - `params` - Map of request parameters
  - `opts` - Options:
    - `:default_limit` - Default limit (default: 20)
    - `:max_limit` - Maximum allowed limit (default: 100)

  ## Returns

  Keyword list suitable for Ash pagination: `[offset: offset, limit: limit]`

  ## Example

      pagination_params(%{"offset" => "20", "limit" => "50"})
      # => [offset: 20, limit: 50]

      pagination_params(%{}, default_limit: 10, max_limit: 50)
      # => [offset: 0, limit: 10]
  """
  def pagination_params(params, opts \\ []) do
    default_limit = Keyword.get(opts, :default_limit, 20)
    max_limit = Keyword.get(opts, :max_limit, 100)

    offset = parse_int(params["offset"], 0, 0)
    limit = min(parse_int(params["limit"], default_limit, 1), max_limit)

    [offset: offset, limit: limit]
  end

  defp parse_int(nil, default, _min), do: default

  defp parse_int(value, default, min) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> max(int, min)
      _ -> default
    end
  end

  defp parse_int(value, _default, min) when is_integer(value), do: max(value, min)
  defp parse_int(_, default, _min), do: default
end
