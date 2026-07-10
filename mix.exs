defmodule AshFeatureFlags.MixProject do
  use Mix.Project

  @description """
  Runtime-toggled boolean feature flags for Ash 3.x: compile-time-validated flag
  declarations, copy-free reads from :persistent_term, and optional multi-node
  invalidation over Phoenix.PubSub.
  """

  @version "0.1.0"

  @source_url "https://github.com/marot/ash_feature_flags"

  def project do
    [
      app: :ash_feature_flags,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      consolidate_protocols: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:ash, :mix]],
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      test_coverage: [
        summary: [threshold: 80],
        ignore_modules: [
          ~r/^AshFeatureFlags\.Dsl\./,
          Mix.Tasks.AshFeatureFlags.Install
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support/", "lib/"]
  defp elixirc_paths(_env), do: ["lib/"]

  defp package do
    [
      name: :ash_feature_flags,
      licenses: ["MIT"],
      files:
        ~w(lib .formatter.exs mix.exs README* LICENSE* usage-rules.md CHANGELOG* documentation),
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "usage-rules.md",
        "documentation/dsls/DSL-AshFeatureFlags.md"
      ],
      groups_for_extras: [
        "DSL Reference": ~r"documentation/dsls/.*"
      ]
    ]
  end

  defp deps do
    [
      {:ash, "~> 3.5 and >= 3.5.5"},
      {:spark, "~> 2.2"},
      {:telemetry, "~> 1.2"},
      {:phoenix_pubsub, "~> 2.1", optional: true},
      {:igniter, "~> 0.5", optional: true},
      # Dev/test dependencies
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:claude, "~> 0.5", only: [:dev], runtime: false},
      {:picosat_elixir, "~> 0.2", only: [:dev, :test]},
      {:git_hooks, "~> 0.8.0", only: [:dev], runtime: false},
      {:ex_check, "~> 0.12", only: [:dev, :test]},
      {:git_ops, "~> 2.9", only: [:dev]},
      {:ex_doc, "~> 0.34", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      sync_usage_rules:
        "usage_rules.sync CLAUDE.md --all --inline usage_rules:all --link-to-folder deps",
      "spark.formatter": "spark.formatter --extensions AshFeatureFlags",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshFeatureFlags",
      sobelow: "sobelow --skip",
      credo: "credo --strict"
    ]
  end
end
