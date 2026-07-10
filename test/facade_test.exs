defmodule AshFeatureFlags.FacadeTest do
  use ExUnit.Case, async: false

  setup do
    Support.Reset.store(Support.FlagStore)
    Support.Reset.runtime(Support.Flags)
    start_supervised!(Support.Flags)
    _ = :sys.get_state(AshFeatureFlags.Cache.name(Support.Flags))
    :ok
  end

  describe "put/2 and reset/1" do
    test "put persists an override the writer sees immediately" do
      assert Support.Flags.enabled?(:off) == false
      assert {:ok, true} = Support.Flags.put(:off, true)
      assert Support.Flags.enabled?(:off) == true
      assert Support.Flags.all() == %{on: true, off: true}
    end

    test "reset deletes the override and reverts to the declared default" do
      {:ok, true} = Support.Flags.put(:off, true)
      assert Support.Flags.enabled?(:off) == true

      assert Support.Flags.reset(:off) == :ok
      assert Support.Flags.enabled?(:off) == false
    end

    test "put rejects non-boolean values" do
      assert_raise ArgumentError, ~r/boolean/, fn ->
        Support.Flags.put(:off, "true")
      end
    end
  end

  describe "list/0" do
    test "reports default vs override source and full metadata" do
      {:ok, true} = Support.Flags.put(:off, true)

      list = Support.Flags.list()
      by_name = Map.new(list, &{&1.name, &1})

      assert by_name[:on] == %{
               name: :on,
               default: true,
               value: true,
               description: "A flag that defaults on.",
               source: :default
             }

      assert by_name[:off] == %{
               name: :off,
               default: false,
               value: true,
               description: "A flag that defaults off.",
               source: :override
             }
    end
  end

  describe "unknown flags" do
    test "put raises on an undeclared flag" do
      assert_raise AshFeatureFlags.UnknownFlagError, ~r/Declared flags/, fn ->
        Support.Flags.put(:nope, true)
      end
    end

    test "reset raises on an undeclared flag" do
      assert_raise AshFeatureFlags.UnknownFlagError, fn ->
        Support.Flags.reset(:nope)
      end
    end
  end

  describe "facade without a store" do
    setup do
      Support.Reset.runtime(Support.CheckFlags)
      :ok
    end

    test "put returns an error and reset still reverts locally" do
      assert Support.CheckFlags.put(:off, true) == {:error, :no_store}
      assert Support.CheckFlags.reset(:off) == :ok
      assert Support.CheckFlags.enabled?(:off) == false
    end
  end
end
