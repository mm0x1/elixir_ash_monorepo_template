import Config

config :template_app, TemplateAppWeb.Endpoint,
  force_ssl: [
    hsts: true,
    rewrite_on: [:x_forwarded_proto, :x_forwarded_host, :x_forwarded_port]
  ],
  http_options: [log_exceptions_with_status_codes: []],
  session: [
    store: :cookie,
    key: "_template_app_key",
    signing_salt: "O9miAQI7",
    max_age: 60 * 60 * 24 * 30,
    http_only: true,
    secure: true,
    same_site: "Lax"
  ]

config :template_app, :serve_frontend, true

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
