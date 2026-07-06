# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :realworld, RealworldWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: RealworldWeb.ErrorHTML, json: RealworldWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Realworld.PubSub,
  live_view: [signing_salt: "WoMwX3/2"]

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

config :realworld, :ash_domains, [Realworld.Accounts, Realworld.Articles, Realworld.Profiles]

config :realworld, ecto_repos: [Realworld.Repo]

# The authentication token signing secret is environment-specific:
# throwaway literals live in dev.exs/test.exs, and prod reads
# TOKEN_SIGNING_SECRET from the environment in runtime.exs.

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
