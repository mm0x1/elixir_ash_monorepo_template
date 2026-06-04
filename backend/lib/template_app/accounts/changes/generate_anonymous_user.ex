defmodule TemplateApp.Accounts.Changes.GenerateAnonymousUser do
  @moduledoc "Creates an anonymous user with random credentials."

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _ctx) do
    suffix =
      4
      |> :crypto.strong_rand_bytes()
      |> Base.encode16(case: :lower)

    changeset
    |> Ash.Changeset.change_attribute(:username, "anon_#{suffix}")
    |> Ash.Changeset.change_attribute(:is_anonymous, true)
    |> Ash.Changeset.change_attribute(:hashed_password, Argon2.hash_pwd_salt(suffix))
  end
end
