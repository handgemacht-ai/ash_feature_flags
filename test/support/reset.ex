defmodule Support.Reset do
  @moduledoc false

  @doc "Destroy every persisted override row for the given store resource."
  def store(resource) do
    {:ok, rows} = Ash.read(resource)
    Enum.each(rows, &Ash.destroy!/1)
    :ok
  end

  @doc "Drop a facade's seeded `:persistent_term` entry."
  def runtime(facade) do
    :persistent_term.erase(AshFeatureFlags.Runtime.key(facade))
    :ok
  end
end
