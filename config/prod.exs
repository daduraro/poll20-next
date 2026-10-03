import Config

# Runtime configuration (DATABASE_URL, SECRET_KEY_BASE, PHX_HOST, PORT)
# lives in config/runtime.exs.

# Do not print debug messages in production
config :logger, level: :info
