defmodule TemplateApp.Accounts.Changes.GenerateRecoveryCodes do
  @moduledoc "Generates recovery codes. Replaces any existing codes."

  use Ash.Resource.Change

  @code_length 10

  # Base32 encodes 5 bits per character. 8 random bytes (64 bits) → 13 Base32 characters.
  # We truncate to @code_length, discarding the last 3, keeping the entropy we need.
  @random_source_bytes 8

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
      @random_source_bytes
      |> :crypto.strong_rand_bytes()
      |> Base.encode32(padding: false)
      |> binary_part(0, length)
      |> String.upcase()
    end
  end
end
