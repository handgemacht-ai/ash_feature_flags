ExUnit.start()

{:ok, _pid} =
  Supervisor.start_link([{Phoenix.PubSub, name: Support.PubSub}], strategy: :one_for_one)
