defmodule AshFeatureFlags.Dsl do
  @moduledoc """
  Spark DSL extension providing the `flags` section.

  Hosted on a facade module via `use AshFeatureFlags`:

      defmodule MyApp.Flags do
        use AshFeatureFlags, otp_app: :my_app, store: MyApp.FeatureFlagStore

        flags do
          flag :new_checkout do
            default false
            description "Route orders through the rewritten checkout pipeline."
          end
        end
      end
  """

  @flag %Spark.Dsl.Entity{
    name: :flag,
    describe: "Declare a single boolean feature flag.",
    target: AshFeatureFlags.Dsl.Flag,
    args: [:name],
    identifier: :name,
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The unique flag key, referenced from application code."
      ],
      default: [
        type: :boolean,
        required: false,
        default: false,
        doc: "Value used until an override is persisted."
      ],
      description: [
        type: :string,
        required: false,
        doc: "Shown in introspection / admin UIs."
      ]
    ]
  }

  @flags %Spark.Dsl.Section{
    name: :flags,
    describe: "Declare the boolean feature flags this facade knows about.",
    entities: [@flag]
  }

  use Spark.Dsl.Extension,
    sections: [@flags],
    transformers: [AshFeatureFlags.Dsl.Transformers.ValidateFlags]
end
