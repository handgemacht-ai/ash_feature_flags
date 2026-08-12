defmodule AshFeatureFlags.Store do
  @moduledoc """
  Behaviour for the persistence backend that holds flag overrides.

  The database stores overrides only; declared defaults live in code, so a cold
  store behaves like a reset to defaults. The default implementation is
  `AshFeatureFlags.Store.Ash`.

  Callbacks receive the facade config struct, which carries `:store` (the Ash
  resource) and any other configured options.
  """

  @type config :: AshFeatureFlags.Config.t()

  @callback all(config()) :: {:ok, %{atom() => boolean()}} | {:error, term()}
  @callback put(config(), atom(), boolean()) :: :ok | {:error, term()}
  @callback delete(config(), atom()) :: :ok | {:error, term()}
end
