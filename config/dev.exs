import Config

# git_ops drives automated versioning and changelog entries from conventional
# commits. It is configured here but tagging/publishing is done manually.
config :git_ops,
  mix_project: Mix.Project.get!(),
  changelog_file: "CHANGELOG.md",
  repository_url: "https://github.com/handgemacht-ai/ash_feature_flags",
  manage_mix_version?: true,
  manage_readme_version: "README.md",
  version_tag_prefix: "v",
  types: [
    tidbit: [hidden?: true],
    important: [header: "Important Changes"]
  ]

config :git_hooks,
  auto_install: false,
  verbose: true,
  hooks: [
    pre_commit: [
      tasks: [
        {:cmd, "mix format --check-formatted"}
      ]
    ]
  ]
