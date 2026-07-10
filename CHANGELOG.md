# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0]

### Added
- Spark DSL for declaring boolean feature flags (`flags do flag :x do default …; description … end end`) with compile-time validation.
- Copy-free reads from `:persistent_term` via `AshFeatureFlags.Runtime`; reads never touch the database.
- Per-facade `AshFeatureFlags.Cache` GenServer that seeds declared defaults synchronously and loads persisted overrides asynchronously with backoff.
- Pluggable `AshFeatureFlags.Store` behaviour with a default Ash-backed implementation and a `Store.Resource` macro that works on any Ash data layer.
- Optional multi-node invalidation over `Phoenix.PubSub`; correct on a single node without it.
- Introspection API (`all/0`, `list/0`) for building admin screens.
- Change telemetry (always) and check telemetry (opt-in).

<!-- changelog -->
