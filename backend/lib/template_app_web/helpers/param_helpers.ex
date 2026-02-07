defmodule TemplateAppWeb.Helpers.ParamHelpers do
  @moduledoc """
  Utilities for safely parsing and handling request parameters.
  """

  @doc """
  Safely parses an integer from various input types.
  Returns default value if parsing fails.

  ## Parameters

    * `value` - The value to parse (can be integer, string, or any other type)
    * `default` - The default value to return if parsing fails

  ## Examples

      iex> ParamHelpers.parse_integer(42, 1)
      42

      iex> ParamHelpers.parse_integer("42", 1)
      42

      iex> ParamHelpers.parse_integer("abc", 1)
      1

      iex> ParamHelpers.parse_integer(nil, 1)
      1
  """
  @spec parse_integer(integer() | String.t() | any(), integer()) :: integer()
  def parse_integer(value, _default) when is_integer(value), do: value

  def parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  def parse_integer(_, default), do: default
end
