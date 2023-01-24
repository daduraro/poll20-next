# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :poll20,
  ash_apis: [
    Poll20,
  ],
  ecto_repos: [Poll20.Repo]

# Configures the endpoint
config :poll20, Poll20Web.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: Poll20Web.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Poll20.PubSub,
  live_view: [signing_salt: "tR39QVxO"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :poll20, Poll20.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# backwards-compat fix as requested by the docs
config :ash, :use_all_identities_in_manage_relationship?, false
config :ash, :policies, show_policy_breakdowns?: true
config :ash, :policies, log_successful_policy_breakdowns: :info
config :ash, :policies, log_policy_breakdowns: :info

config :mime, :types, %{
  "application/vnd.api+json" => ["json"]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
