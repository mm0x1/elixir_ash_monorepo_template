defmodule TemplateApp.Domains.Accounts.Changes.GenerateRecoveryCodes do
  @moduledoc "Generates recovery codes. Replaces any existing codes."

  use Ash.Resource.Change

  @code_length 10

  @impl true
  def change(changeset, _opts, _ctx) do
    code_count = TemplateApp.Config.recovery_code_count()
    codes = generate_codes(code_count, @code_length)
    hashed = Enum.map(codes, &Argon2.hash_pwd_salt/1)

    changeset
    |> Ash.Changeset.change_attribute(:recovery_codes, hashed)
    |> Ash.Changeset.change_attribute(:recovery_codes_generated_at, DateTime.utc_now())
    |> Ash.Changeset.after_action(fn _cs, record ->
      {:ok, %{record | __metadata__: Map.put(record.__metadata__, :plain_recovery_codes, codes)}}
    end)
  end

  defp generate_codes(count, length) do
    for _ <- 1..count do
      8
      |> :crypto.strong_rand_bytes()
      |> Base.encode32(padding: false)
      |> binary_part(0, length)
      |> String.upcase()
    end
  end
end
