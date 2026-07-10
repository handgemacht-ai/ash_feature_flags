defmodule AshFeatureFlags.UnknownFlagError do
  @moduledoc """
  Raised when a flag key that was never declared on a facade is read or written.
  """

  defexception [:flag, :facade, :valid]

  @impl true
  def message(%{flag: flag, facade: facade, valid: valid}) do
    declared = Enum.map_join(valid, ", ", &inspect/1)
    "unknown feature flag #{inspect(flag)} for #{inspect(facade)}. Declared flags: #{declared}"
  end
end
