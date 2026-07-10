defmodule AshFeatureFlags.CacheTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias AshFeatureFlags.Cache

  setup do
    Support.Reset.store(Support.FlagStore)
    Support.Reset.runtime(Support.Flags)
    :ok
  end

  defp seed_override(key, value) do
    Support.FlagStore
    |> Ash.Changeset.for_create(:upsert, %{key: key, value: value})
    |> Ash.create!()
  end

  defp config(overrides) do
    Support.Flags.__ash_feature_flags_config__()
    |> Map.merge(Map.new(overrides))
  end

  test "seeds declared defaults synchronously then loads persisted overrides" do
    seed_override(:off, true)

    start_supervised!(Support.Flags)
    _ = :sys.get_state(Cache.name(Support.Flags))

    assert Support.Flags.enabled?(:off) == true
    assert Support.Flags.all() == %{on: true, off: true}
  end

  test "filters override rows for flags that are no longer declared" do
    seed_override(:off, true)
    seed_override(:ghost, true)

    start_supervised!(Support.Flags)
    _ = :sys.get_state(Cache.name(Support.Flags))

    assert Support.Flags.all() == %{on: true, off: true}
    refute Map.has_key?(Support.Flags.all(), :ghost)
  end

  test "keeps defaults, logs a warning, and stays alive when the store load fails" do
    cfg =
      config(
        store_backend: Support.FailingStore,
        on_load_error: :defaults,
        retry_ms: 60_000,
        name: :aff_cache_load_error
      )

    log =
      capture_log(fn ->
        pid =
          start_supervised!(%{
            id: :load_error_cache,
            start: {AshFeatureFlags.Cache, :start_link, [cfg]}
          })

        _ = :sys.get_state(pid)
      end)

    assert log =~ "override load failed"
    assert Support.Flags.all() == %{on: true, off: false}

    state = :sys.get_state(:aff_cache_load_error)
    assert state.attempts >= 1
  end

  test "crashes the cache when the store fails and on_load_error is :raise" do
    cfg =
      config(
        store_backend: Support.FailingStore,
        on_load_error: :raise,
        name: :aff_cache_raise
      )

    Process.flag(:trap_exit, true)

    capture_log(fn ->
      {:ok, pid} = AshFeatureFlags.Cache.start_link(cfg)
      assert_receive {:EXIT, ^pid, {:load_failed, :boom}}, 1_000
    end)
  end
end
