defmodule TemplateApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :template_app,
      version: "0.1.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      usage_rules: usage_rules(),
      compilers: Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      consolidate_protocols: Mix.env() != :dev,
      # Endpoint force_ssl is intentionally selected from FORCE_SSL at runtime.
      releases: [template_app: [validate_compile_env: false]]
    ]
  end

  # usage_rules: which package rules to sync into backend/AGENTS.md.
  # Config is the source of truth — run `mix usage_rules.sync` to regenerate.
  defp usage_rules do
    [
      file: "AGENTS.md",
      usage_rules: [
        :usage_rules,
        {:ash, sub_rules: []},
        {:ash, sub_rules: :all, main: false, link: :markdown},
        {~r/^ash_/, link: :markdown},
        :igniter
      ]
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
      {:usage_rules, "~> 1.2", only: [:dev]},
      {:picosat_elixir, "~> 0.2"},
      {:sourceror, "~> 1.12", only: [:dev, :test]},
      {:ash_admin, "~> 1.2"},
      {:ash_authentication_phoenix, "~> 2.17"},
      {:ash_authentication, "~> 4.14"},
      {:ash_postgres, "~> 2.11"},
      {:ash_phoenix, "~> 2.3"},
      {:ash, "~> 3.31"},
      {:igniter, "~> 0.8", only: [:dev, :test]},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.7", only: :dev},
      {:phoenix_live_view, "~> 1.2"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.12"},
      {:argon2_elixir, "~> 4.1"},
      {:tidewave, "~> 0.9", only: :dev},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:ash_ops, "~> 0.1", only: [:dev]},
      {:cors_plug, "~> 3.0"},
      {:joken, "~> 2.6"},
      {:hammer, "~> 7.4"}
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
        "run priv/repo/seeds.exs"
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
        "compile --warnings-as-errors"
      ],
      "quality.fix": [
        "format"
      ],
      "assets.setup": [
        "cmd --cd ../frontend npm ci"
      ],
      "assets.build": [
        "cmd --cd ../frontend npm run build"
      ],
      "assets.deploy": [
        "cmd --cd ../frontend npm run build",
        "phx.digest"
      ]
    ]
  end
end
