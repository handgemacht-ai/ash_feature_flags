defmodule AshFeatureFlags.Facade do
  @moduledoc """
  Implementation behind the functions `use AshFeatureFlags` injects onto a
  facade. Each function takes the facade module and reads its configuration from
  `facade.__ash_feature_flags_config__/0`.
  """

  alias AshFeatureFlags.{Info, PubSub, Runtime, Telemetry, UnknownFlagError}

  @type flag_info :: %{
          name: atom(),
          default: boolean(),
          value: boolean(),
          description: String.t() | nil,
          source: :default | :override
        }

  @doc "Read a flag from `:persistent_term`, raising on an undeclared key."
  @spec enabled?(module(), atom()) :: boolean()
  def enabled?(facade, name) do
    case Runtime.fetch(facade, name) do
      {:ok, value} -> value
      :error -> resolve_miss(facade, name)
    end
  end

  @doc "The effective `%{flag => boolean}` map (declared defaults ⊕ overrides)."
  @spec all(module()) :: %{atom() => boolean()}
  def all(facade) do
    case Runtime.all(facade) do
      map when map_size(map) == 0 -> Info.defaults(facade)
      map -> map
    end
  end

  @doc "Per-flag metadata for building admin screens."
  @spec list(module()) :: [flag_info()]
  def list(facade) do
    effective = all(facade)
    overrides = overrides(facade)

    Enum.map(Info.flags(facade), fn flag ->
      value = Map.get(effective, flag.name, flag.default)

      %{
        name: flag.name,
        default: flag.default,
        value: value,
        description: flag.description,
        source: if(Map.has_key?(overrides, flag.name), do: :override, else: :default)
      }
    end)
  end

  @doc "Persist an override and revert only the effective read cache on failure."
  @spec put(module(), atom(), boolean()) :: {:ok, boolean()} | {:error, term()}
  def put(facade, name, value) when is_boolean(value) do
    config = config(facade)
    ensure_declared!(facade, name)

    case config.store_backend.put(config, name, value) do
      :ok ->
        Runtime.put_term(facade, name, value)
        Telemetry.flag_change(facade, name, value)
        PubSub.broadcast(config, {:flags_changed, Runtime.all(facade)})
        {:ok, value}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def put(_facade, name, value) do
    raise ArgumentError,
          "feature flag #{inspect(name)} only accepts boolean values, got: #{inspect(value)}"
  end

  @doc "Delete an override so the flag reverts to its declared default."
  @spec reset(module(), atom()) :: :ok
  def reset(facade, name) do
    config = config(facade)
    ensure_declared!(facade, name)
    default = Info.default(facade, name)

    case config.store_backend.delete(config, name) do
      :ok -> :ok
      {:error, _reason} -> :ok
    end

    Runtime.put_term(facade, name, default)
    Telemetry.flag_change(facade, name, default)
    PubSub.broadcast(config, {:flags_changed, Runtime.all(facade)})
    :ok
  end

  @doc "Supervisor child spec that starts the facade's `AshFeatureFlags.Cache`."
  @spec child_spec(module(), keyword()) :: Supervisor.child_spec()
  def child_spec(facade, init_opts) do
    config = facade |> config() |> merge_runtime_opts(init_opts)

    %{
      id: facade,
      start: {AshFeatureFlags.Cache, :start_link, [config]},
      type: :worker
    }
  end

  defp resolve_miss(facade, name) do
    names = Info.flag_names(facade)

    if name in names do
      Info.default(facade, name)
    else
      raise UnknownFlagError, facade: facade, flag: name, valid: names
    end
  end

  defp overrides(facade) do
    config = config(facade)

    case config.store_backend.all(config) do
      {:ok, overrides} -> overrides
      {:error, _reason} -> %{}
    end
  end

  defp ensure_declared!(facade, name) do
    names = Info.flag_names(facade)

    unless name in names do
      raise UnknownFlagError, facade: facade, flag: name, valid: names
    end

    :ok
  end

  defp config(facade), do: facade.__ash_feature_flags_config__()

  defp merge_runtime_opts(config, init_opts) do
    Enum.reduce(
      [:store, :store_backend, :pubsub, :on_load_error, :check_telemetry, :retry_ms, :name],
      config,
      fn key, acc ->
        case Keyword.fetch(init_opts, key) do
          {:ok, value} -> AshFeatureFlags.Config.put(acc, key, value)
          :error -> acc
        end
      end
    )
  end
end
