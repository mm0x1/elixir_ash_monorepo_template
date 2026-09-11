defmodule TemplateApp.Accounts.Validations.ValidateUsername do
  @moduledoc "Validates the shared username format and length policy."

  use Ash.Resource.Validation

  @min_length 3
  @max_length 30

  @doc false
  def min_length, do: @min_length

  @doc false
  def max_length, do: @max_length

  @impl true
  def validate(changeset, opts, _context) do
    value = value(changeset, opts)

    case value do
      nil ->
        :ok

      value ->
        username = to_string(value)

        cond do
          String.length(username) < @min_length ->
            {:error,
             field: field(opts),
             message:
               "must be #{@min_length}-#{@max_length} characters, letters, numbers, underscore only"}

          String.length(username) > @max_length ->
            {:error,
             field: field(opts),
             message:
               "must be #{@min_length}-#{@max_length} characters, letters, numbers, underscore only"}

          not Regex.match?(~r/^[a-zA-Z0-9_]+$/, username) ->
            {:error,
             field: field(opts),
             message:
               "must be #{@min_length}-#{@max_length} characters, letters, numbers, underscore only"}

          true ->
            :ok
        end
    end
  end

  defp value(changeset, opts) do
    case Keyword.fetch(opts, :argument) do
      {:ok, argument} -> Ash.Changeset.get_argument(changeset, argument)
      :error -> Ash.Changeset.get_attribute(changeset, Keyword.fetch!(opts, :attribute))
    end
  end

  defp field(opts), do: Keyword.get(opts, :attribute, Keyword.get(opts, :argument, :username))
end
