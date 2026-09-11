defmodule TemplateApp.Accounts.Changes.SetUsernameLastChanged do
  @moduledoc """
  Sets the username_last_changed attribute to the current UTC time for rate limiting.
  """

  use Ash.Resource.Change

  alias TemplateApp.Accounts.Validations.UsernameChangeRateLimit

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      case UsernameChangeRateLimit.check(
             Ash.Changeset.get_data(changeset, :username_last_changed)
           ) do
        :ok ->
          Ash.Changeset.force_change_attribute(
            changeset,
            :username_last_changed,
            DateTime.utc_now()
          )

        {:error, error} ->
          Ash.Changeset.add_error(changeset, error)
      end
    end)
  end
end
