defmodule AshFeatureFlags.DslTest do
  use ExUnit.Case, async: true

  alias AshFeatureFlags.Info

  describe "introspection" do
    test "exposes declared flag names in declaration order" do
      assert Info.flag_names(Support.Flags) == [:on, :off]
    end

    test "exposes declared defaults and per-flag defaults" do
      assert Info.defaults(Support.Flags) == %{on: true, off: false}
      assert Info.default(Support.Flags, :on) == true
      assert Info.default(Support.Flags, :off) == false
      assert Info.default(Support.Flags, :missing) == nil
    end

    test "exposes the full flag entity with its description" do
      flag = Info.flag(Support.Flags, :on)
      assert flag.name == :on
      assert flag.default == true
      assert flag.description == "A flag that defaults on."
      assert Info.flag(Support.Flags, :missing) == nil
    end
  end

  describe "compile-time validation" do
    test "duplicate flag names fail to compile" do
      assert_raise Spark.Error.DslError, ~r/unique/, fn ->
        Code.eval_string("""
        defmodule AshFeatureFlags.DslTest.Duplicate do
          use AshFeatureFlags

          flags do
            flag :dup do
              default true
            end

            flag :dup do
              default false
            end
          end
        end
        """)
      end
    end

    test "a non-boolean default fails to compile" do
      assert_raise Spark.Error.DslError, ~r/boolean/, fn ->
        Code.eval_string("""
        defmodule AshFeatureFlags.DslTest.BadDefault do
          use AshFeatureFlags

          flags do
            flag :x do
              default "yes"
            end
          end
        end
        """)
      end
    end
  end
end
