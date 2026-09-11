defmodule TemplateApp.Accounts.Validations.UsernameChangeRateLimit do
  @moduledoc "Enforces username change cooldown period."

  use Ash.Resource.Validation

  @doc false
  def check(last_changed, now \\ DateTime.utc_now()) do
    cooldown_days = TemplateApp.Config.username_change_cooldown_days()

    cond do
      is_nil(last_changed) ->
        :ok

      DateTime.diff(now, last_changed, :day) >= cooldown_days ->
        :ok

      true ->
        days_remaining = cooldown_days - DateTime.diff(now, last_changed, :day)

        {:error,
         field: :username,
         message:
           "can only be changed every #{cooldown_days} days (#{days_remaining} days remaining)"}
    end
  end

  @impl true
  def validate(changeset, _opts, _ctx) do
    changeset
    |> Ash.Changeset.get_data(:username_last_changed)
    |> check()
  end
end
