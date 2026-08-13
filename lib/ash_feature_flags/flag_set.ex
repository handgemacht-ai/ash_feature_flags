defmodule AshFeatureFlags.FlagSet do
  @moduledoc """
  The effective flag set for a facade: declared defaults ⊕ persisted overrides.

  This is the library's central value object. A `FlagSet` carries the
  `%{flag => boolean}` map plus a `source` tag that distinguishes a set built
  from declared defaults (`:defaults`) from one built by merging persisted
  overrides onto defaults (`:effective`). The tag lets callers tell the two
  cases apart without inferring them from the map's size.

  The `:persistent_term` store and the public `Facade.all/1` boundary still
  exchange plain `%{atom => boolean}` maps; `FlagSet` is the named internal
  representation at the sites that construct and merge the set.
  """

  @type source :: :defaults | :effective
  @type flags :: %{atom() => boolean()}

  defstruct [:flags, :source]

  @type t :: %__MODULE__{flags: flags(), source: source()}

  @doc "Build a `FlagSet` from declared defaults."
  @spec from_defaults(flags()) :: t()
  def from_defaults(flags) when is_map(flags),
    do: %__MODULE__{flags: flags, source: :defaults}

  @doc "Build a `FlagSet` from an already-effective map (e.g. a PubSub broadcast)."
  @spec from_effective(flags()) :: t()
  def from_effective(flags) when is_map(flags),
    do: %__MODULE__{flags: flags, source: :effective}

  @doc """
  Merge persisted `overrides` onto declared `defaults`, keeping only override
  rows whose key is a declared flag. The result is the effective set with
  `source: :effective`.
  """
  @spec from_overrides(flags(), flags()) :: t()
  def from_overrides(defaults, overrides) when is_map(defaults) and is_map(overrides) do
    declared = MapSet.new(Map.keys(defaults))

    kept =
      Map.filter(overrides, fn {key, _value} -> MapSet.member?(declared, key) end)

    %__MODULE__{flags: Map.merge(defaults, kept), source: :effective}
  end

  @doc "The underlying `%{flag => boolean}` map."
  @spec to_map(t()) :: flags()
  def to_map(%__MODULE__{flags: flags}), do: flags
end
