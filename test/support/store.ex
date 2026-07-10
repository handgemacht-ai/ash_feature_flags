defmodule Support.FlagStore do
  @moduledoc false
  use AshFeatureFlags.Store.Resource,
    domain: Support.Domain,
    data_layer: Ash.DataLayer.Ets
end
