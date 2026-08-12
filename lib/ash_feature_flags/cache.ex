defmodule AshFeatureFlags.Cache do
  @moduledoc """
  One GenServer per facade. On boot it seeds declared defaults into
  `:persistent_term` synchronously, so reads work immediately, then loads
  persisted overrides asynchronously. It subscribes to PubSub and applies
  `{:flags_changed, map}` broadcasts, and retries a failed load with backoff.

  Boot never blocks on the store and, with `on_load_error: :defaults` (the
  default), never crashes when the store is unreachable.
  """

  use GenServer

  require Logger

  alias AshFeatureFlags.{Info, PubSub, Runtime}

  @max_backoff_ms 30_000
  @max_attempts 10

  @spec start_link(AshFeatureFlags.Config.t()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: config.name || name(config.facade))
  end

  @doc "Registered name of the cache process for a facade."
  @spec name(module()) :: module()
  def name(facade), do: Module.concat(facade, Cache)

  @impl true
  def init(config) do
    defaults = Info.defaults(config.facade)
    Runtime.seed(config.facade, defaults)
    PubSub.subscribe(config)
    send(self(), :load)

    {:ok, %{config: config, defaults: defaults, current: defaults, attempts: 0}}
  end

  @impl true
  def handle_info(:load, state) do
    config = state.config

    case config.store_backend.all(config) do
      {:ok, overrides} ->
        {:noreply, apply_overrides(state, overrides)}

      {:error, reason} ->
        case config.on_load_error do
          :raise -> {:stop, {:load_failed, reason}, state}
          :defaults -> {:noreply, retry_after_error(state, reason)}
        end
    end
  end

  def handle_info({:flags_changed, map}, state) when is_map(map) do
    Runtime.seed(state.config.facade, map)
    {:noreply, %{state | current: map}}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp apply_overrides(state, overrides) do
    declared = MapSet.new(Map.keys(state.defaults))
    kept = Map.filter(overrides, fn {key, _value} -> MapSet.member?(declared, key) end)

    log_stale(overrides, kept, state.config.facade)

    effective = Map.merge(state.defaults, kept)
    Runtime.seed(state.config.facade, effective)
    %{state | current: effective, attempts: 0}
  end

  defp retry_after_error(state, reason) do
    Logger.warning(
      "[ash_feature_flags] override load failed for #{inspect(state.config.facade)}: " <>
        "#{inspect(reason)}; keeping defaults and retrying"
    )

    Process.send_after(self(), :load, backoff(state.attempts, state.config))
    %{state | attempts: min(state.attempts + 1, @max_attempts)}
  end

  defp log_stale(overrides, kept, facade) do
    stale = Map.keys(overrides) -- Map.keys(kept)

    if stale != [] do
      Logger.debug(
        "[ash_feature_flags] ignoring undeclared flag rows for #{inspect(facade)}: " <>
          inspect(stale)
      )
    end
  end

  defp backoff(attempts, config) do
    base = config.retry_ms
    min(base * Integer.pow(2, attempts), @max_backoff_ms)
  end
end
