defmodule TemplateApp.Accounts.Validations.UsernameChangeRateLimit do
  @moduledoc "Enforces username change cooldown period."

  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _ctx) do
    last_changed = Ash.Changeset.get_data(changeset, :username_last_changed)
    cooldown_days = TemplateApp.Config.username_change_cooldown_days()

    cond do
      is_nil(last_changed) ->
        :ok

      DateTime.diff(DateTime.utc_now(), last_changed, :day) >= cooldown_days ->
        :ok

      true ->
        days_remaining = cooldown_days - DateTime.diff(DateTime.utc_now(), last_changed, :day)

        {:error,
         field: :username,
         message:
           "can only be changed every #{cooldown_days} days (#{days_remaining} days remaining)"}
    end
  end
end
