# AshFeatureFlags

[![Hex.pm](https://img.shields.io/hexpm/v/ash_feature_flags.svg)](https://hex.pm/packages/ash_feature_flags)
[![Hexdocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ash_feature_flags)
[![CI](https://github.com/marot/ash_feature_flags/actions/workflows/ci.yml/badge.svg)](https://github.com/marot/ash_feature_flags/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Runtime-toggled boolean feature flags for [Ash](https://ash-hq.org) 3.x.

- **Declared in code.** The set of known flags is a compile-time-validated
  [Spark](https://hexdocs.pm/spark) DSL: unique names, boolean defaults,
  generated docs and cheat sheets.
- **Reads never touch the database.** `enabled?/1` is a copy-free
  `:persistent_term` lookup — safe on any hot path.
- **Writes go through Ash.** Overrides upsert into a consumer-owned Ash
  resource on any data layer (Postgres in prod, ETS in tests) and invalidate
  every node via optional `Phoenix.PubSub`.
- **Boot never blocks on the database.** Declared defaults are seeded
  synchronously; persisted overrides load asynchronously with backoff.

## When to use a flag (and when not to)

Flags gate *behaviour* at runtime: rollout switches, kill switches, admin
toggles. Module choices, adapters, ports, and other boot-time seams stay in
Application config — they are wiring, not behaviour, and should not change
under a running system.

## Installation

Add `ash_feature_flags` to your dependencies:

```elixir
def deps do
  [
    {:ash_feature_flags, "~> 0.1"},
    # Optional, for multi-node invalidation:
    {:phoenix_pubsub, "~> 2.1"}
  ]
end
```

## Usage

Define a storage resource (any Ash data layer works):

```elixir
defmodule MyApp.FeatureFlagStore do
  use AshFeatureFlags.Store.Resource,
    domain: MyApp.Admin,
    data_layer: AshPostgres.DataLayer,
    repo: MyApp.Repo,
    table: "feature_flags"
end
```

Define your flag facade — the registry of every flag your app knows about:

```elixir
defmodule MyApp.Flags do
  use AshFeatureFlags,
    otp_app: :my_app,
    store: MyApp.FeatureFlagStore,
    pubsub: MyApp.PubSub

  flags do
    flag :new_checkout do
      default false
      description "Route orders through the rewritten checkout pipeline."
    end

    flag :semantic_review do
      default true
      description "Second-opinion LLM consensus on top of deterministic checks."
    end
  end
end
```

Start the facade's cache after your Repo and PubSub:

```elixir
children = [
  MyApp.Repo,
  {Phoenix.PubSub, name: MyApp.PubSub},
  MyApp.Flags
]
```

Then, at any call site:

```elixir
if MyApp.Flags.enabled?(:new_checkout) do
  NewCheckout.process(order)
else
  LegacyCheckout.process(order)
end
```

Toggling from an admin context:

```elixir
{:ok, true} = MyApp.Flags.put(:new_checkout, true)   # persist an override
:ok = MyApp.Flags.reset(:new_checkout)               # revert to the declared default
```

Undeclared keys fail fast: `MyApp.Flags.enabled?(:typo)` raises
`AshFeatureFlags.UnknownFlagError` listing the valid names.

## Introspection / building an admin screen

`list/0` returns everything an admin UI needs; `all/0` returns the effective
value map:

```elixir
MyApp.Flags.all()
#=> %{new_checkout: true, semantic_review: true}

MyApp.Flags.list()
#=> [
#     %{
#       name: :new_checkout,
#       default: false,
#       value: true,
#       description: "Route orders through the rewritten checkout pipeline.",
#       source: :override
#     },
#     ...
#   ]
```

A LiveView admin screen is a table over `list/0` with a toggle calling
`put/2` and a reset button calling `reset/1` — no extra API needed.

## Telemetry

- `[:ash_feature_flags, :flag, :change]` — emitted on every `put/2` and
  `reset/1`. Always on.
- `[:ash_feature_flags, :flag, :check]` — emitted on every `enabled?/1`.
  Opt in per facade with `check_telemetry: true`.

Both events carry measurements `%{count: 1}` and metadata
`%{facade: module, flag: atom, value: boolean}`.

## Configuration

Options accepted by `use AshFeatureFlags`:

| Option | Default | Purpose |
|---|---|---|
| `:otp_app` | — | Your OTP application. |
| `:store` | `nil` | The `AshFeatureFlags.Store.Resource` resource holding overrides. |
| `:store_backend` | `AshFeatureFlags.Store.Ash` | Alternative `AshFeatureFlags.Store` implementation. |
| `:pubsub` | `nil` | `Phoenix.PubSub` name for multi-node invalidation. |
| `:on_load_error` | `:defaults` | `:defaults` keeps declared defaults and retries with backoff; `:raise` crashes the cache. |
| `:check_telemetry` | `false` | Emit a telemetry event on every read. |
| `:retry_ms` | `1000` | Base backoff between failed override loads. |

## Testing your flags

Point the store at ETS and everything works without Postgres:

```elixir
defmodule MyApp.Test.FlagStore do
  use AshFeatureFlags.Store.Resource,
    domain: MyApp.Test.Domain,
    data_layer: Ash.DataLayer.Ets
end
```

Start the facade with `start_supervised!/1`, then use `put/2` and `reset/1` in
tests exactly like production code. See this repo's `test/` directory for
patterns (synchronizing on the cache with `:sys.get_state/1` instead of
sleeping).

## Semantics worth knowing

- **Defaults live in code, the DB stores only overrides** — a cold database
  behaves like "everything reset to defaults".
- **`put/2` is O(n) over the flag map** (`:persistent_term` global GC): fine
  for rare admin writes, which is what it is for.
- **Removed a flag from code but a row remains?** The row is ignored (debug
  log) until you delete it.
- **Concurrent writes:** last write wins.
- **Multi-node needs PubSub.** Without it, a single node stays fully correct;
  other nodes only converge on their next boot.

## Documentation

- [API docs on hexdocs](https://hexdocs.pm/ash_feature_flags)
- [DSL cheat sheet](documentation/dsls/DSL-AshFeatureFlags.md)
- [Usage rules](usage-rules.md)

## License

MIT — see [LICENSE](LICENSE).
