defmodule AshFeatureFlags do
  @moduledoc """
  Runtime-toggled boolean feature flags for Ash 3.x.

  `use AshFeatureFlags` turns a module into a flag facade: it hosts the `flags`
  DSL, injects the public API (`enabled?/1`, `put/2`, `reset/1`, `all/0`,
  `list/0`, `child_spec/1`), and knows how to persist overrides.

      defmodule MyApp.Flags do
        use AshFeatureFlags, otp_app: :my_app, store: MyApp.FeatureFlagStore, pubsub: MyApp.PubSub

        flags do
          flag :new_checkout do
            default false
            description "Route orders through the rewritten checkout pipeline."
          end
        end
      end

  Reads (`MyApp.Flags.enabled?(:new_checkout)`) are served from
  `:persistent_term` and never touch the database. Writes
  (`MyApp.Flags.put(:new_checkout, true)`) upsert through Ash and invalidate
  every node over PubSub.

  ## Options

    * `:otp_app` — the OTP application (used for app-env configuration).
    * `:store` — the `AshFeatureFlags.Store.Resource` resource that holds
      overrides. Required for `put/2` and `reset/1`.
    * `:store_backend` — the `AshFeatureFlags.Store` implementation.
      Defaults to `AshFeatureFlags.Store.Ash`.
    * `:pubsub` — a `Phoenix.PubSub` name for multi-node invalidation.
      Omit for single-node deployments.
    * `:on_load_error` — `:defaults` (keep declared defaults and retry, the
      default) or `:raise` (crash the cache) when the store fails at boot.
    * `:check_telemetry` — emit `[:ash_feature_flags, :flag, :check]` on every
      `enabled?/1`. Defaults to `false`.
    * `:retry_ms` — base backoff between failed override loads. Defaults to
      `1000`.
  """

  use Spark.Dsl,
    default_extensions: [extensions: [AshFeatureFlags.Dsl]],
    opt_schema: [
      store: [
        type: :atom,
        doc: "The Ash resource that persists flag overrides."
      ],
      store_backend: [
        type: :atom,
        default: AshFeatureFlags.Store.Ash,
        doc: "The `AshFeatureFlags.Store` implementation."
      ],
      pubsub: [
        type: :atom,
        doc: "A `Phoenix.PubSub` name for multi-node invalidation."
      ],
      on_load_error: [
        type: {:in, [:defaults, :raise]},
        default: :defaults,
        doc: "How the cache reacts when the store fails to load overrides."
      ],
      check_telemetry: [
        type: :boolean,
        default: false,
        doc: "Emit a telemetry event on every `enabled?/1` read."
      ],
      retry_ms: [
        type: :pos_integer,
        default: 1000,
        doc: "Base backoff, in milliseconds, between failed override loads."
      ]
    ]

  @impl Spark.Dsl
  def handle_opts(opts) do
    config = %AshFeatureFlags.Config{
      otp_app: opts[:otp_app],
      store: opts[:store],
      store_backend: opts[:store_backend],
      pubsub: opts[:pubsub],
      on_load_error: opts[:on_load_error],
      check_telemetry: opts[:check_telemetry],
      retry_ms: opts[:retry_ms],
      facade: nil,
      name: nil
    }

    enabled_def = enabled_def(opts[:check_telemetry])

    quote location: :keep do
      @__ash_feature_flags_config__ AshFeatureFlags.Config.put(
                                      unquote(Macro.escape(config)),
                                      :facade,
                                      __MODULE__
                                    )

      @doc false
      @spec __ash_feature_flags_config__() :: AshFeatureFlags.Config.t()
      def __ash_feature_flags_config__, do: @__ash_feature_flags_config__

      @doc "Whether `flag` is currently enabled. Raises on an undeclared flag."
      @spec enabled?(atom()) :: boolean()
      unquote(enabled_def)

      @doc "Persist an override for `flag`."
      @spec put(atom(), boolean()) :: {:ok, boolean()} | {:error, term()}
      def put(flag, value), do: AshFeatureFlags.Facade.put(__MODULE__, flag, value)

      @doc "Delete `flag`'s override so it reverts to its declared default."
      @spec reset(atom()) :: :ok
      def reset(flag), do: AshFeatureFlags.Facade.reset(__MODULE__, flag)

      @doc "The effective `%{flag => boolean}` map."
      @spec all() :: %{atom() => boolean()}
      def all, do: AshFeatureFlags.Facade.all(__MODULE__)

      @doc "Per-flag metadata for admin screens."
      @spec list() :: [AshFeatureFlags.Facade.flag_info()]
      def list, do: AshFeatureFlags.Facade.list(__MODULE__)

      @doc false
      def child_spec(init_opts), do: AshFeatureFlags.Facade.child_spec(__MODULE__, init_opts)
    end
  end

  defp enabled_def(true) do
    quote do
      def enabled?(flag) do
        value = AshFeatureFlags.Facade.enabled?(__MODULE__, flag)
        AshFeatureFlags.Telemetry.flag_check(__MODULE__, flag, value)
        value
      end
    end
  end

  defp enabled_def(_false) do
    quote do
      def enabled?(flag), do: AshFeatureFlags.Facade.enabled?(__MODULE__, flag)
    end
  end

  @doc false
  def sections, do: AshFeatureFlags.Dsl.sections()

  @doc false
  def dsl_patches, do: AshFeatureFlags.Dsl.dsl_patches()
end
