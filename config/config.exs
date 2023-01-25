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

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# backwards-compat fix as requested by the docs
config :ash, :use_all_identities_in_manage_relationship?, false
config :ash, :policies, log_policy_breakdowns: :error

config :mime, :types, %{
  "application/vnd.api+json" => ["json"]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
