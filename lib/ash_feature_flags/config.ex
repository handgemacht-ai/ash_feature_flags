defmodule AshFeatureFlags.Config do
  @moduledoc """
  The typed facade configuration that threads through the library's cache,
  store, and pubsub seams.

  Built by `use AshFeatureFlags` from the validated `opt_schema` options and
  attached to the facade module as `__ash_feature_flags_config__/0`. Every
  library module reads this struct instead of an open `map()`, so an unknown
  option key or an unknown `on_load_error` policy is caught at compile time
  rather than silently swallowed at runtime.
  """

  @enforce_keys [:facade, :store, :store_backend]
  defstruct [
    :facade,
    :store,
    :store_backend,
    :pubsub,
    :on_load_error,
    :check_telemetry,
    :retry_ms,
    :otp_app,
    :name
  ]

  @typedoc "Closed set of cache boot policies for a failed override load."
  @type on_load_error :: :defaults | :raise

  @typedoc "The facade configuration shared across the cache, store, and pubsub."
  @type t :: %__MODULE__{
          facade: module() | nil,
          store: module() | nil,
          store_backend: module(),
          pubsub: module() | nil,
          on_load_error: on_load_error(),
          check_telemetry: boolean() | nil,
          retry_ms: pos_integer() | nil,
          otp_app: atom() | nil,
          name: GenServer.name() | nil
        }

  @doc """
  Return a new `t` with `key` set to `value`.

  Rejects keys that are not part of the config struct — a typo in a runtime
  override raises instead of silently widening the shape.
  """
  @spec put(t(), atom(), term()) :: t()
  def put(%__MODULE__{} = config, key, value) do
    case key do
      :facade -> %{config | facade: value}
      :store -> %{config | store: value}
      :store_backend -> %{config | store_backend: value}
      :pubsub -> %{config | pubsub: value}
      :on_load_error -> %{config | on_load_error: value}
      :check_telemetry -> %{config | check_telemetry: value}
      :retry_ms -> %{config | retry_ms: value}
      :otp_app -> %{config | otp_app: value}
      :name -> %{config | name: value}
      other -> raise ArgumentError, "unknown AshFeatureFlags.Config key: #{inspect(other)}"
    end
  end
end
