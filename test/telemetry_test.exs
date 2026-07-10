defmodule AshFeatureFlags.TelemetryTest do
  use ExUnit.Case, async: false

  setup do
    Support.Reset.store(Support.FlagStore)
    Support.Reset.runtime(Support.Flags)
    Support.Reset.runtime(Support.CheckFlags)
    start_supervised!(Support.Flags)
    _ = :sys.get_state(AshFeatureFlags.Cache.name(Support.Flags))
    :ok
  end

  defp attach(event) do
    handler = "test-#{System.unique_integer([:positive])}"
    test = self()

    :telemetry.attach(
      handler,
      event,
      fn name, measurements, metadata, _ ->
        send(test, {:telemetry, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler) end)
  end

  describe "change telemetry" do
    test "is emitted on every put and reset" do
      attach([:ash_feature_flags, :flag, :change])

      {:ok, true} = Support.Flags.put(:off, true)

      assert_receive {:telemetry, [:ash_feature_flags, :flag, :change], %{count: 1},
                      %{facade: Support.Flags, flag: :off, value: true}}

      :ok = Support.Flags.reset(:off)

      assert_receive {:telemetry, [:ash_feature_flags, :flag, :change], %{count: 1},
                      %{facade: Support.Flags, flag: :off, value: false}}
    end
  end

  describe "check telemetry" do
    test "is emitted per read only when opted in" do
      attach([:ash_feature_flags, :flag, :check])

      assert Support.CheckFlags.enabled?(:on) == true

      assert_receive {:telemetry, [:ash_feature_flags, :flag, :check], %{count: 1},
                      %{facade: Support.CheckFlags, flag: :on, value: true}}

      assert Support.Flags.enabled?(:on) == true
      refute_receive {:telemetry, [:ash_feature_flags, :flag, :check], _, _}
    end
  end
end
