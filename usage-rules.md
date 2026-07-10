# AshFeatureFlags Usage Rules

Runtime-toggled boolean feature flags for Ash 3.x. Reads are copy-free
`:persistent_term` lookups; writes upsert through Ash and invalidate every node
via optional PubSub.

## When to use a flag vs Application config

- Use a flag for **behaviour that must change under a running system**:
  rollouts, kill switches, admin toggles.
- Keep **module choices, adapters, ports, and boot-time seams in Application
  config**. Those are wiring, not behaviour.

## Declare before use — fail fast

- Every flag must be declared in the facade's `flags do ... end` block.
- Reading or writing an undeclared key raises
  `AshFeatureFlags.UnknownFlagError` listing the valid names. Do not rescue
  this error to "default to false" — fix the declaration instead.
- Duplicate names and non-boolean defaults fail at compile time.

## Supervision

- Start the facade (its `Cache`) **after** your Repo and PubSub:

  ```elixir
  children = [MyApp.Repo, {Phoenix.PubSub, name: MyApp.PubSub}, MyApp.Flags]
  ```

- The cache seeds declared defaults synchronously; `enabled?/1` is correct from
  the instant the facade starts, even if the database is down.
- Do not call `enabled?/1` before the facade's application has booted if you
  need override values; you would see declared defaults.

## Reads are free, writes are rare

- `enabled?/1` never touches the database or the cache process — call it on
  hot paths freely.
- `put/2` and `reset/1` write through Ash, replace the `:persistent_term`
  entry (global GC), and broadcast to every node. Reserve them for admin
  actions, not request paths.

## Defaults live in code, the DB stores only overrides

- A cold database means "everything at its declared default".
- Changing a default in code changes the value everywhere no override exists.
- Rows for flags no longer declared in code are ignored (with a debug log);
  delete them at your leisure.

## Storage resource

- Generate it with `use AshFeatureFlags.Store.Resource` and supply
  `domain`, `data_layer`, and (for Postgres) `repo` + `table`.
- The facade module and the storage resource are deliberately separate
  modules: registry/API is one thing, persistence another.

## Testing with ETS

- Point the store at `Ash.DataLayer.Ets` — no Postgres needed:

  ```elixir
  use AshFeatureFlags.Store.Resource,
    domain: MyTest.Domain,
    data_layer: Ash.DataLayer.Ets
  ```

- Start the facade with `start_supervised!(MyApp.Flags)`.
- Synchronize on the cache with `:sys.get_state/1` rather than `Process.sleep`.

## Multi-node

- Pass `pubsub: MyApp.PubSub` for cross-node invalidation. Without it a single
  node is fully correct; other nodes only converge on their next boot.
- Concurrent writes are last-write-wins.

## Boolean only, global only (v0.1)

- Flags are booleans with one global value. No per-actor targeting, no
  percentage rollouts, no non-boolean values. Do not encode variants into flag
  names to work around this; wait for or contribute the feature.
