defmodule Support.Flags do
  @moduledoc false
  use AshFeatureFlags,
    otp_app: :ash_feature_flags,
    store: Support.FlagStore,
    pubsub: Support.PubSub

  flags do
    flag :on do
      default true
      description "A flag that defaults on."
    end

    flag :off do
      default false
      description "A flag that defaults off."
    end
  end
end
