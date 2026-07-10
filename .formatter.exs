spark_locals_without_parens = [default: 1, description: 1, flag: 1, flag: 2]

[
  locals_without_parens: spark_locals_without_parens,
  import_deps: [:spark],
  export: [
    locals_without_parens: spark_locals_without_parens
  ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
