import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :realworld, RealworldWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "lZwKjZGfO8/fLAiFStlp9+zCpdIG3iz0b51uFhkcgn/Tel2A5b/5L93L1BbjcbuK",
  server: false

# In test we don't send emails.
config :realworld, Realworld.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
