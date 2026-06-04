defmodule TemplateApp.Accounts.Changes.SetTokenExpiry do
  @moduledoc "Sets expires_at on a refresh token to now + lifetime_days."

  use Ash.Resource.Change

  @impl true
  def change(changeset, opts, _ctx) do
    lifetime_days =
      opts[:lifetime_days] || raise ArgumentError, "lifetime_days option is required"

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(lifetime_days, :day)
      |> DateTime.truncate(:microsecond)

    Ash.Changeset.force_change_attribute(changeset, :expires_at, expires_at)
  end
end
