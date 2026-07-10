defmodule AshFeatureFlags.PubSubTest do
  use ExUnit.Case, async: false

  alias AshFeatureFlags.{Cache, PubSub}

  setup do
    Support.Reset.store(Support.FlagStore)
    Support.Reset.runtime(Support.Flags)
    :ok
  end

  describe "no-op without pubsub" do
    test "subscribe and broadcast return :ok when pubsub is nil" do
      config = %{pubsub: nil, facade: Support.CheckFlags}

      assert PubSub.subscribe(config) == :ok
      assert PubSub.broadcast(config, {:flags_changed, %{}}) == :ok
    end
  end

  describe "topic" do
    test "is namespaced by facade" do
      assert PubSub.topic(Support.Flags) == "ash_feature_flags:Support.Flags"
    end
  end

  describe "multi-node invalidation" do
    test "a write on one cache is applied by a second subscribed cache" do
      start_supervised!(Support.Flags)
      _ = :sys.get_state(Cache.name(Support.Flags))

      second_config =
        Support.Flags.__ash_feature_flags_config__()
        |> Map.put(:name, :aff_cache_node_b)

      node_b =
        start_supervised!(%{
          id: :node_b,
          start: {AshFeatureFlags.Cache, :start_link, [second_config]}
        })

      _ = :sys.get_state(node_b)

      assert :sys.get_state(node_b).current == %{on: true, off: false}

      {:ok, true} = Support.Flags.put(:off, true)

      # Draining node B's mailbox guarantees it processed the broadcast.
      assert :sys.get_state(node_b).current == %{on: true, off: true}
    end
  end
end
