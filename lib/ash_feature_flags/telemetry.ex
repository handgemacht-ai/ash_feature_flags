defmodule AshFeatureFlags.Telemetry do
  @moduledoc """
  Telemetry events emitted by the library.

    * `[:ash_feature_flags, :flag, :change]` — emitted on every `put/2` and
      `reset/1`. Always on.
    * `[:ash_feature_flags, :flag, :check]` — emitted on every `enabled?/1`.
      Opt-in per facade via `check_telemetry: true`.

  Both carry measurements `%{count: 1}` and metadata
  `%{facade: module, flag: atom, value: boolean}`.
  """

  @change_event [:ash_feature_flags, :flag, :change]
  @check_event [:ash_feature_flags, :flag, :check]

  @spec flag_change(module(), atom(), boolean()) :: :ok
  def flag_change(facade, flag, value) do
    :telemetry.execute(@change_event, %{count: 1}, %{facade: facade, flag: flag, value: value})
  end

  @spec flag_check(module(), atom(), boolean()) :: :ok
  def flag_check(facade, flag, value) do
    :telemetry.execute(@check_event, %{count: 1}, %{facade: facade, flag: flag, value: value})
  end
end
