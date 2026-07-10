defmodule AshFeatureFlags.Store.Resource do
  @moduledoc """
  Generates a consumer-owned Ash resource that stores flag overrides.

  The resource has `key` and `value` attributes, an `:upsert` action keyed on
  `key`, plus `:read` and `:destroy`. The consumer supplies the data layer, so
  it runs on Postgres in production and on ETS in tests.

      defmodule MyApp.FeatureFlagStore do
        use AshFeatureFlags.Store.Resource,
          domain: MyApp.Admin,
          data_layer: AshPostgres.DataLayer,
          repo: MyApp.Repo,
          table: "feature_flags"
      end
  """

  defmacro __using__(opts) do
    domain = Keyword.fetch!(opts, :domain)
    data_layer = Keyword.get(opts, :data_layer, Ash.DataLayer.Ets)
    otp_app = Keyword.get(opts, :otp_app)
    repo = Keyword.get(opts, :repo)
    table = Keyword.get(opts, :table)
    pre_check_with = Keyword.get(opts, :pre_check_with, domain)

    postgres_block =
      if repo && table do
        quote do
          postgres do
            table(unquote(table))
            repo(unquote(repo))
          end
        end
      end

    identity_block =
      if pre_check_with do
        quote do
          identity :key, [:key] do
            pre_check_with(unquote(pre_check_with))
          end
        end
      else
        quote do
          identity(:key, [:key])
        end
      end

    quote do
      use Ash.Resource,
        otp_app: unquote(otp_app),
        domain: unquote(domain),
        data_layer: unquote(data_layer)

      unquote(postgres_block)

      attributes do
        uuid_primary_key(:id)

        attribute :key, :atom do
          allow_nil?(false)
          public?(true)
        end

        attribute :value, :boolean do
          allow_nil?(false)
          public?(true)
        end
      end

      actions do
        defaults([:read, :destroy])

        create :upsert do
          description("Upsert a single flag override, keyed by :key.")
          upsert?(true)
          upsert_identity(:key)
          accept([:key, :value])
        end
      end

      identities do
        unquote(identity_block)
      end
    end
  end
end
