defmodule AshFeatureFlags.PubSub do
  @moduledoc """
  Thin wrapper over `Phoenix.PubSub` for multi-node invalidation.

  Every function is a no-op when the facade was configured without a `:pubsub`
  or when `phoenix_pubsub` is not loaded, so a single node stays correct without
  the optional dependency.
  """

  @spec topic(module()) :: String.t()
  def topic(facade), do: "ash_feature_flags:" <> inspect(facade)

  @spec subscribe(map()) :: :ok | {:error, term()}
  def subscribe(%{pubsub: nil}), do: :ok

  def subscribe(%{pubsub: pubsub, facade: facade}) do
    if available?() do
      Phoenix.PubSub.subscribe(pubsub, topic(facade))
    else
      :ok
    end
  end

  @spec broadcast(map(), term()) :: :ok | {:error, term()}
  def broadcast(%{pubsub: nil}, _message), do: :ok

  def broadcast(%{pubsub: pubsub, facade: facade}, message) do
    if available?() do
      Phoenix.PubSub.broadcast(pubsub, topic(facade), message)
    else
      :ok
    end
  end

  defp available?, do: Code.ensure_loaded?(Phoenix.PubSub)
end
