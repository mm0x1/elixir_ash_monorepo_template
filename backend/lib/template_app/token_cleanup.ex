defmodule TemplateApp.TokenCleanup do
  @moduledoc """
  Performs bounded cleanup of expired authentication records.

  A single GenServer owns the schedule, so cleanup calls cannot overlap. Each
  run deletes at most one batch from each authentication table; the next
  scheduled run continues where the previous run stopped.
  """

  use GenServer

  import Ecto.Query

  alias TemplateApp.Accounts.Resources.{RefreshToken, Token}
  alias TemplateApp.Repo

  require Logger

  @batch_size 500

  @doc "Starts the periodic cleanup process."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Returns whether the supervised cleanup process should run."
  def enabled? do
    Application.get_env(:template_app, :token_cleanup_enabled, true)
  end

  @doc "Runs one bounded cleanup pass synchronously."
  def cleanup_once(opts \\ []) do
    batch_size = Keyword.get(opts, :batch_size, @batch_size)
    started_at = System.monotonic_time()

    try do
      result =
        with {:ok, token_count} <- delete_expired(Token, :jti, batch_size),
             {:ok, refresh_session_count} <- delete_expired(RefreshToken, :id, batch_size) do
          {:ok, %{token_count: token_count, refresh_session_count: refresh_session_count}}
        end

      log_result(result, elapsed_ms(started_at))
      result
    rescue
      _error ->
        Logger.error("Authentication token cleanup failed",
          error_category: "database",
          duration_ms: elapsed_ms(started_at)
        )

        {:error, :cleanup_failed}
    end
  end

  @doc "Runs one cleanup pass through a supervised worker."
  def run_once(server \\ __MODULE__), do: GenServer.call(server, :cleanup_once, 30_000)

  @impl true
  def init(opts) do
    interval_ms = Keyword.get(opts, :interval_ms, TemplateApp.Config.token_cleanup_interval_ms())
    initial_delay_ms = Keyword.get(opts, :initial_delay_ms, interval_ms)
    {:ok, schedule(%{interval_ms: interval_ms}, initial_delay_ms)}
  end

  @impl true
  def handle_call(:cleanup_once, _from, state) do
    {:reply, cleanup_once(), state}
  end

  @impl true
  def handle_info(:cleanup, %{interval_ms: interval_ms} = state) do
    cleanup_once()
    {:noreply, schedule(state, interval_ms)}
  end

  defp schedule(state, :infinity), do: state

  defp schedule(state, delay_ms) do
    Process.send_after(self(), :cleanup, delay_ms)
    state
  end

  defp delete_expired(resource, primary_key, batch_size) do
    now = DateTime.utc_now()

    expired_ids =
      from(record in resource,
        where: record.expires_at < ^now,
        order_by: [asc: record.expires_at],
        limit: ^batch_size,
        select: field(record, ^primary_key)
      )

    {count, _returned_rows} =
      Repo.delete_all(
        from(record in resource,
          where: field(record, ^primary_key) in subquery(expired_ids)
        )
      )

    {:ok, count}
  rescue
    _error -> {:error, :database}
  end

  defp elapsed_ms(started_at) do
    System.monotonic_time()
    |> Kernel.-(started_at)
    |> System.convert_time_unit(:native, :millisecond)
  end

  defp log_result({:ok, counts}, duration_ms) do
    Logger.info("Authentication token cleanup completed",
      token_count: counts.token_count,
      refresh_session_count: counts.refresh_session_count,
      duration_ms: duration_ms
    )
  end

  defp log_result({:error, _reason}, duration_ms) do
    Logger.error("Authentication token cleanup failed",
      error_category: "database",
      duration_ms: duration_ms
    )
  end
end
