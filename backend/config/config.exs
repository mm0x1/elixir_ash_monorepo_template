# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# esbuild configuration removed - using Vite from frontend/ folder instead

config :ash,
  allow_forbidden_field_for_relationships_by_default?: true,
  include_embedded_source_by_default?: false,
  show_keysets_for_all_actions?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false],
  keep_read_action_loads_when_loading?: false,
  default_actions_require_atomic?: true,
  read_action_after_action_hooks_in_order?: true,
  default_string_length_count: :codepoints,
  bulk_actions_default_to_errors?: true

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :admin,
        :authentication,
        :tokens,
        :postgres,
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [
      section_order: [
        :admin,
        :resources,
        :policies,
        :authorization,
        :domain,
        :execution
      ]
    ]
  ]

config :template_app,
  ecto_repos: [TemplateApp.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [
    TemplateApp.Accounts
  ]

# Configures the endpoint
config :template_app, TemplateAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TemplateAppWeb.ErrorHTML, json: TemplateAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TemplateApp.PubSub,
  live_view: [signing_salt: "O9miAQI7"]

# Note: Response compression should be handled at the infrastructure level
# (nginx, load balancer, CDN) for optimal performance

# Configures Elixir's Logger with enhanced metadata
# Declaring all metadata keys enables structured logging and log aggregation
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    # Request context
    :request_id,
    :user_id,
    :username,
    :method,
    :path,
    :status,
    :duration_ms,
    :params,
    :remote_ip,

    # Resource operations
    :operation,
    :resource_type,
    :resource_id,
    :event_type,

    # Ash framework telemetry
    :domain,
    :resource,
    :action,
    :action_type,
    :kind,
    :reason,

    # Error tracking & correlation
    :error,
    :error_id,
    :error_type,

    # Client-side error logging
    :client_url,
    :client_user_agent,
    :client_timestamp,
    :client_error_id,

    # Notifications
    :notification_ids,

    # Search/pagination
    :search_query,
    :page
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
