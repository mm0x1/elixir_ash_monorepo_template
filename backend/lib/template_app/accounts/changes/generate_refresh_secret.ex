defmodule TemplateApp.Accounts.Changes.GenerateRefreshSecret do
  @moduledoc "Generates a one-time refresh bearer secret and stores only its digest."

  use Ash.Resource.Change

  @secret_bytes 32

  @impl true
  def change(changeset, _opts, _context) do
    secret =
      @secret_bytes
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    secret_hash = :crypto.hash(:sha256, secret)

    changeset
    |> Ash.Changeset.force_change_attribute(:secret_hash, secret_hash)
    |> Ash.Changeset.after_action(fn _changeset, record ->
      {:ok,
       %{
         record
         | __metadata__: Map.put(record.__metadata__, :plain_refresh_secret, secret)
       }}
    end)
  end
end
