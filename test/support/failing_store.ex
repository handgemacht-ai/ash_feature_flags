defmodule Support.FailingStore do
  @moduledoc false
  @behaviour AshFeatureFlags.Store

  @impl true
  def all(_config), do: {:error, :boom}

  @impl true
  def put(_config, _flag, _value), do: {:error, :boom}

  @impl true
  def delete(_config, _flag), do: {:error, :boom}
end
