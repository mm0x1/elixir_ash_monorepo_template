alias TemplateApp.Accounts
alias TemplateApp.Accounts.Resources.User
require Ash.Query

defmodule Seeder do
  def run do
    IO.puts("Starting seeds...")

    IO.puts("1. Creating users with different roles...")
    create_user_with_role("user", "password123", :user)
    create_user_with_role("admin", "password123", :admin)
    create_user_with_role("superadmin", "password123", :superadmin)

    IO.puts("\nSeeds completed successfully!")
    IO.puts("\nTest accounts:")
    IO.puts("  - user/password123 (role: user)")
    IO.puts("  - admin/password123 (role: admin)")
    IO.puts("  - superadmin/password123 (role: superadmin)")
  end

  def create_user_with_role(username, password, role) do
    case User
         |> Ash.Query.filter(username == ^username)
         |> Ash.read_one() do
      {:ok, nil} ->
        {:ok, user} =
          Accounts.create_user(username, password, password, authorize?: false)

        update_role(user, role)

        IO.puts("   - Created user: #{username} (role: #{role})")
        user

      {:ok, user} ->
        update_role(user, role)

        IO.puts("   - Updated user: #{username} (role: #{role})")
        user

      {:error, _} ->
        nil
    end
  end

  defp update_role(user, role) do
    # Keep seed-only role assignment out of the public Ash action surface.
    TemplateApp.Repo.query!(
      "UPDATE users SET role = $1, updated_at = NOW() WHERE id = $2",
      [Atom.to_string(role), Ecto.UUID.dump!(user.id)]
    )

    {:ok, updated_user} = Accounts.get_user_by_id(user.id)
    updated_user
  end
end

Seeder.run()
