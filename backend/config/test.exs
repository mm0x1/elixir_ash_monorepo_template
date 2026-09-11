import Config

config :template_app,
  dev_routes: false,
  allow_privileged_seeds: false,
  token_signing_secret: "l8smtRvlNLSrp7Gwdu+3kn/uAIhHEjNY",
  ash_auth_signing_secret: "x7mQpRvKt9nWfYc3bJ5hLe8gAi2dUo4s"

config :ash, policies: [show_policy_breakdowns?: true]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :template_app, TemplateApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "test_db#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :template_app, TemplateAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "arbu7Dx9F1/9SZgeFz7ts9Clpu8OZpLAysK2Jy2GoHqipfJKi04GQS/2PH36Lt16",
  server: false

config :cors_plug,
  origin: ["http://localhost:5173", "http://127.0.0.1:5173"]

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
