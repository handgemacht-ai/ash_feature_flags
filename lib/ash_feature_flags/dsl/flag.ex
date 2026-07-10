defmodule AshFeatureFlags.Dsl.Flag do
  @moduledoc """
  Struct backing a single `flag` entity in the `flags` DSL section.
  """

  defstruct name: nil,
            default: false,
            description: nil,
            __identifier__: nil,
            __spark_metadata__: nil

  @type t :: %__MODULE__{
          name: atom(),
          default: boolean(),
          description: String.t() | nil,
          __identifier__: term()
        }
end
