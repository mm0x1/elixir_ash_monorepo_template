alias TemplateApp.Domains.Accounts
alias TemplateApp.Domains.Accounts.Resources.User
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

        # Update role after creation
        {:ok, user} =
          user
          |> Ash.Changeset.for_update(:update, %{})
          |> Ash.Changeset.force_change_attribute(:role, role)
          |> Ash.update(authorize?: false)

        IO.puts("   - Created user: #{username} (role: #{role})")
        user

      {:ok, user} ->
        # Update role if user exists
        {:ok, user} =
          user
          |> Ash.Changeset.for_update(:update, %{})
          |> Ash.Changeset.force_change_attribute(:role, role)
          |> Ash.update(authorize?: false)

        IO.puts("   - Updated user: #{username} (role: #{role})")
        user

      {:error, _} ->
        nil
    end
  end
end

Seeder.run()
