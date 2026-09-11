defmodule TemplateApp.TokenCleanupTest do
  use TemplateApp.DataCase, async: false

  import Ecto.Query
  import TemplateApp.UserFixtures

  alias TemplateApp.Accounts.RefreshSessions
  alias TemplateApp.Accounts.Resources.{RefreshToken, Token}
  alias TemplateApp.TokenCleanup

  defp expired_datetime(type) do
    DateTime.utc_now()
    |> DateTime.add(-3600, :second)
    |> DateTime.truncate(type)
  end

  defp active_datetime(type) do
    DateTime.utc_now()
    |> DateTime.add(3600, :second)
    |> DateTime.truncate(type)
  end

  defp insert_token(jti, expires_at) do
    Repo.insert_all(Token, [
      %{
        jti: jti,
        subject: "cleanup-test",
        expires_at: expires_at,
        purpose: "test",
        extra_data: %{}
      }
    ])
  end

  defp create_refresh_session(user) do
    {:ok, refresh_secret} = RefreshSessions.issue(user, "cleanup-test")
    secret_hash = :crypto.hash(:sha256, refresh_secret)
    Repo.one!(from(token in RefreshToken, where: token.secret_hash == ^secret_hash))
  end

  test "the periodic worker is disabled in the test environment" do
    refute TokenCleanup.enabled?()
  end

  test "removes expired records while preserving active sessions and is idempotent" do
    user = create_user()
    expired_refresh = create_refresh_session(user)
    active_refresh = create_refresh_session(user)

    Repo.update_all(
      from(token in RefreshToken, where: token.id == ^expired_refresh.id),
      set: [expires_at: expired_datetime(:microsecond)]
    )

    Repo.update_all(
      from(token in RefreshToken, where: token.id == ^active_refresh.id),
      set: [expires_at: active_datetime(:microsecond)]
    )

    expired_jti = "expired-#{System.unique_integer([:positive])}"
    active_jti = "active-#{System.unique_integer([:positive])}"
    insert_token(expired_jti, expired_datetime(:second))
    insert_token(active_jti, active_datetime(:second))

    assert {:ok, %{token_count: 1, refresh_session_count: 1}} = TokenCleanup.cleanup_once()

    assert Repo.one(from(token in Token, where: token.jti == ^expired_jti, select: token.jti)) ==
             nil

    assert Repo.one(from(token in Token, where: token.jti == ^active_jti, select: token.jti)) ==
             active_jti

    assert Repo.get(RefreshToken, expired_refresh.id) == nil
    assert Repo.get(RefreshToken, active_refresh.id) != nil

    assert {:ok, %{token_count: 0, refresh_session_count: 0}} = TokenCleanup.cleanup_once()
  end

  test "deletes no more than the configured batch size per table" do
    expired_jtis =
      for _ <- 1..2 do
        jti = "expired-#{System.unique_integer([:positive])}"
        insert_token(jti, expired_datetime(:second))
        jti
      end

    assert {:ok, %{token_count: 1, refresh_session_count: 0}} =
             TokenCleanup.cleanup_once(batch_size: 1)

    assert length(
             Repo.all(from(token in Token, where: token.jti in ^expired_jtis, select: token.jti))
           ) == 1

    assert {:ok, %{token_count: 1, refresh_session_count: 0}} =
             TokenCleanup.cleanup_once(batch_size: 1)

    assert Repo.all(from(token in Token, where: token.jti in ^expired_jtis, select: token.jti)) ==
             []

    refute Enum.any?(expired_jtis, &Repo.get(Token, &1))
  end

  test "the supervised worker can run without a timer and restart" do
    name = String.to_atom("token_cleanup_#{System.unique_integer([:positive])}")

    pid =
      start_supervised!(
        {TokenCleanup, name: name, interval_ms: :infinity, initial_delay_ms: :infinity}
      )

    assert Process.alive?(pid)
    assert {:ok, %{token_count: 0, refresh_session_count: 0}} = TokenCleanup.run_once(name)

    Process.exit(pid, :kill)

    assert eventually(fn ->
             case Process.whereis(name) do
               restarted when is_pid(restarted) -> restarted != pid and Process.alive?(restarted)
               _ -> false
             end
           end)
  end

  defp eventually(fun, attempts \\ 20)
  defp eventually(_fun, 0), do: false

  defp eventually(fun, attempts) do
    if fun.() do
      true
    else
      Process.sleep(10)
      eventually(fun, attempts - 1)
    end
  end
end
