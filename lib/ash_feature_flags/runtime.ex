defmodule AshFeatureFlags.Runtime do
  @moduledoc """
  The `:persistent_term` engine backing flag reads.

  The effective `%{flag => boolean}` map for a facade lives under the term key
  `{AshFeatureFlags, facade}`. Reads are copy-free lookups; writes replace the
  term and trigger a global GC, so they are reserved for rare admin toggles and
  boot-time seeding, never for reads.
  """

  @spec key(module()) :: {AshFeatureFlags, module()}
  def key(facade), do: {AshFeatureFlags, facade}

  @doc "Replace the full effective flag map for a facade."
  @spec seed(module(), %{atom() => boolean()}) :: :ok
  def seed(facade, map) when is_map(map) do
    :persistent_term.put(key(facade), map)
  end

  @doc "The full effective flag map, or an empty map when nothing is seeded yet."
  @spec all(module()) :: %{atom() => boolean()}
  def all(facade), do: :persistent_term.get(key(facade), %{})

  @doc "Fetch a single flag value from the seeded map."
  @spec fetch(module(), atom()) :: {:ok, boolean()} | :error
  def fetch(facade, name), do: Map.fetch(all(facade), name)

  @doc "Read a single flag value, or `nil` when absent."
  @spec get(module(), atom()) :: boolean() | nil
  def get(facade, name), do: Map.get(all(facade), name)

  @doc "Merge one flag value into the seeded map."
  @spec put_term(module(), atom(), boolean()) :: :ok
  def put_term(facade, name, value) do
    seed(facade, Map.put(all(facade), name, value))
  end
end
