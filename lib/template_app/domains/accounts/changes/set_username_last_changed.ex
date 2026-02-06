defmodule TemplateApp.Domains.Accounts.Changes.SetUsernameLastChanged do
  @moduledoc """
  Sets the username_last_changed attribute to the current UTC time for rate limiting.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.force_change_attribute(changeset, :username_last_changed, DateTime.utc_now())
  end
end
