defmodule Poll20.MixProject do
  use Mix.Project

  def project do
    [
      app: :poll20,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def application do
    [
      mod: {Poll20.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.34"},
      {:ash_json_api, "~> 1.7"},
      # Optional dep of ash_json_api, but its request validation calls AshJsonApi.OpenApi
      # (only compiled when open_api_spex is present), so it's effectively required.
      {:open_api_spex, "~> 3.22"},
      {:ash_postgres, "~> 2.14"},
      {:picosat_elixir, "~> 0.2"},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.7"},
      {:bandit, "~> 1.12"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:cors_plug, "~> 3.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:igniter, "~> 0.8", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.12", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "api.spec": &api_spec/1
    ]
  end

  # OpenAPI spec of the JSON:API, source of the frontend's types (`pnpm api:types`).
  # `mix api.spec --check=true` fails if the committed spec is outdated
  defp api_spec(args) do
    Mix.Task.run("openapi.spec.json", [
      "--spec",
      "Poll20.Router",
      "--filename",
      "priv/openapi.json",
      "--start-app=false",
      "--pretty=true",
      "--vendor-extensions=false"
      | args
    ])
  end
end
