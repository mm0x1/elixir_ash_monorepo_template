defmodule TemplateApp.Accounts.Changes.ConvertToRegistered do
  @moduledoc "Sets username, hashes password, and clears the anonymous flag when converting a guest account."

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _ctx) do
    password = Ash.Changeset.get_argument(changeset, :password)
    confirmation = Ash.Changeset.get_argument(changeset, :password_confirmation)
    username = Ash.Changeset.get_argument(changeset, :username)

    if password != confirmation do
      Ash.Changeset.add_error(changeset,
        field: :password_confirmation,
        message: "must match password"
      )
    else
      changeset
      |> Ash.Changeset.change_attribute(:username, username)
      |> Ash.Changeset.change_attribute(:hashed_password, Argon2.hash_pwd_salt(password))
      |> Ash.Changeset.change_attribute(:is_anonymous, false)
    end
  end
end
