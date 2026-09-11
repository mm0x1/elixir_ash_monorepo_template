defmodule TemplateApp.Accounts.Validations.ValidatePasswordPolicy do
  @moduledoc "Validates the shared password length policy."

  use Ash.Resource.Validation

  @min_length 8
  @max_length 128

  @doc false
  def max_length, do: @max_length

  @doc false
  def within_max_length?(password) when is_binary(password),
    do: String.length(password) <= @max_length

  def within_max_length?(_password), do: false

  @impl true
  def validate(changeset, opts, _context) do
    argument = Keyword.fetch!(opts, :argument)
    password = Ash.Changeset.get_argument(changeset, argument)

    cond do
      is_nil(password) or not is_binary(password) ->
        :ok

      String.length(password) < @min_length ->
        {:error, field: argument, message: "must be at least #{@min_length} characters"}

      String.length(password) > @max_length ->
        {:error, field: argument, message: "must be at most #{@max_length} characters"}

      true ->
        :ok
    end
  end
end
