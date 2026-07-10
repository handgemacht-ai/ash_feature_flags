[
  ## all available options with default values (see `mix check` docs for description)
  # parallel: true,
  # skipped: true,

  ## list of tools (see `mix check` docs for defaults)
  tools: [
    {:check_cheat_sheets, command: "mix spark.cheat_sheets --check"},
    {:check_formatter, command: "mix spark.formatter --check"},
    {:doctor, false}
  ]
]
