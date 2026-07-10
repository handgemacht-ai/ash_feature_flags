defmodule AshFeatureFlags.RuntimeTest do
  use ExUnit.Case, async: false

  alias AshFeatureFlags.Runtime

  setup do
    Support.Reset.store(Support.FlagStore)
    Support.Reset.runtime(Support.Flags)
    :ok
  end

  test "the term key is namespaced by facade" do
    assert Runtime.key(Support.Flags) == {AshFeatureFlags, Support.Flags}
  end

  test "reads fall back to declared defaults before the cache seeds the term" do
    assert Support.Flags.enabled?(:on) == true
    assert Support.Flags.enabled?(:off) == false
  end

  test "seeded values are served from persistent_term" do
    Runtime.seed(Support.Flags, %{on: false, off: true})

    assert Runtime.all(Support.Flags) == %{on: false, off: true}
    assert Runtime.fetch(Support.Flags, :on) == {:ok, false}
    assert Runtime.get(Support.Flags, :off) == true
    assert Support.Flags.enabled?(:on) == false
    assert Support.Flags.enabled?(:off) == true
  end

  test "put_term merges a single value into the seeded map" do
    Runtime.seed(Support.Flags, %{on: true, off: false})
    Runtime.put_term(Support.Flags, :off, true)

    assert Runtime.all(Support.Flags) == %{on: true, off: true}
  end

  test "enabled?/1 raises on an undeclared flag" do
    assert_raise AshFeatureFlags.UnknownFlagError, ~r/:nope/, fn ->
      Support.Flags.enabled?(:nope)
    end
  end
end
