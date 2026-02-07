defmodule TemplateApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :template_app,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      consolidate_protocols: Mix.env() != :dev
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TemplateApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:bcrypt_elixir, "~> 3.0"},
      {:picosat_elixir, "~> 0.2"},
      {:sourceror, "~> 1.8", only: [:dev, :test]},
      {:ash_cloak, "~> 0.2"},
      {:cloak, "~> 1.0"},
      {:ash_admin, "~> 0.13.24"},
      {:ash_authentication_phoenix, "~> 2.15"},
      {:ash_authentication, "~> 4.13"},
      {:ash_postgres, "~> 2.6"},
      {:ash_phoenix, "~> 2.3"},
      {:ash, "~> 3.13"},
      {:igniter, "~> 0.7", only: [:dev, :test]},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.19"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.8"},
      {:argon2_elixir, "~> 4.1"},
      {:ash_rate_limiter, "~> 0.2"},
      {:tidewave, "~> 0.5", only: :dev},
      {:mox, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.18", only: [:dev, :test]},
      {:stream_data, "~> 1.1"},
      {:ash_ops, "~> 0.1", only: [:dev]},
      {:ash_typescript, "~> 0.11"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: [
        "deps.get",
        "ash.setup",
        "assets.setup",
        "assets.build",
        "run priv/repo/seeds.exs",
        "cmd lefthook install"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "codegen.dev": ["ash.codegen --dev"],
      "codegen.dry": ["ash.codegen --dry-run"],
      codegen: ["ash.codegen"],
      "codegen.check": ["ash.codegen --check"],
      "ecto.migrate": ["ecto.migrate"],
      test: ["ash.setup --quiet", "test"],
      quality: [
        "format --check-formatted",
        "credo --strict",
        "compile --warnings-as-errors",
        "cmd --cd frontend npm run lint"
      ],
      "quality.fix": [
        "format",
        "cmd --cd frontend npm run lint:fix"
      ],
      "assets.setup": [
        "tailwind.install --if-missing",
        "cmd --cd frontend npm install"
      ],
      "assets.build": [
        "tailwind template_app",
        "cmd --cd frontend npx vite build --config vite.config.js"
      ],
      "assets.deploy": [
        "tailwind template_app --minify",
        "cmd --cd frontend npx vite build --mode production --config vite.config.js",
        "phx.digest"
      ]
    ]
  end
end
