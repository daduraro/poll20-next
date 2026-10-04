[
  import_deps: [
    :ash,
    :ash_json_api,
    :ash_postgres,
    :ecto,
    :phoenix
  ],
  # Spark.Formatter: Ash DSL parens and section order (see `config :spark` in config.exs)
  # Styler: rewrites code to a consistent style on top of the regular formatting
  plugins: [Spark.Formatter, Styler],
  inputs: [
    "*.{ex,exs}",
    "priv/*/seeds.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  subdirectories: [
    "priv/*/migrations"
  ]
]
