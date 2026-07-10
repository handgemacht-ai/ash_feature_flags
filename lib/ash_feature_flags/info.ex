defmodule AshFeatureFlags.Info do
  @moduledoc """
  Introspection over the flags declared on a facade module.
  """

  alias AshFeatureFlags.Dsl.Flag

  @doc "All declared `#{inspect(Flag)}` entities for a facade."
  @spec flags(module()) :: [Flag.t()]
  def flags(facade) do
    facade
    |> Spark.Dsl.Extension.get_entities([:flags])
    |> List.wrap()
    |> Enum.filter(&match?(%Flag{}, &1))
  end

  @doc "The declared flag with the given name, or `nil`."
  @spec flag(module(), atom()) :: Flag.t() | nil
  def flag(facade, name) do
    Enum.find(flags(facade), &(&1.name == name))
  end

  @doc "The declared flag names for a facade."
  @spec flag_names(module()) :: [atom()]
  def flag_names(facade) do
    Enum.map(flags(facade), & &1.name)
  end

  @doc "The declared default for a single flag, or `nil` when it is undeclared."
  @spec default(module(), atom()) :: boolean() | nil
  def default(facade, name) do
    case flag(facade, name) do
      %Flag{default: default} -> default
      _ -> nil
    end
  end

  @doc "The declared defaults for a facade as a `%{name => default}` map."
  @spec defaults(module()) :: %{atom() => boolean()}
  def defaults(facade) do
    Map.new(flags(facade), &{&1.name, &1.default})
  end
end
