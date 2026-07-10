defmodule AshFeatureFlags.StoreAshTest do
  use ExUnit.Case, async: false

  alias AshFeatureFlags.Store.Ash, as: Store

  @config %{store: Support.FlagStore}

  setup do
    Support.Reset.store(Support.FlagStore)
    :ok
  end

  test "round-trips overrides through read, upsert, and destroy" do
    assert Store.all(@config) == {:ok, %{}}

    assert Store.put(@config, :off, true) == :ok
    assert Store.all(@config) == {:ok, %{off: true}}

    assert Store.put(@config, :off, false) == :ok
    assert Store.all(@config) == {:ok, %{off: false}}

    assert Store.delete(@config, :off) == :ok
    assert Store.all(@config) == {:ok, %{}}

    assert Store.delete(@config, :off) == :ok
  end

  test "treats a nil store as empty and unwritable" do
    assert Store.all(%{store: nil}) == {:ok, %{}}
    assert Store.put(%{store: nil}, :off, true) == {:error, :no_store}
    assert Store.delete(%{store: nil}, :off) == {:error, :no_store}
  end
end
