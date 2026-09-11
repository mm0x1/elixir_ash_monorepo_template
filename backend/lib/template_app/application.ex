defmodule TemplateApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    TemplateApp.Config.validate!()

    # Attach Ash action telemetry logging (dev only)
    TemplateApp.Logging.AshLogger.attach()

    children = [
      TemplateApp.RateLimit,
      TemplateAppWeb.Telemetry,
      TemplateApp.Repo,
      {DNSCluster, query: Application.get_env(:template_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TemplateApp.PubSub},
      # Start a worker by calling: TemplateApp.Worker.start_link(arg)
      # {TemplateApp.Worker, arg},
      # Start to serve requests, typically the last entry
      TemplateAppWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :template_app]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TemplateApp.Supervisor]

    result = Supervisor.start_link(children, opts)

    # Log successful application startup
    require Logger

    Logger.info("Application started successfully", %{
      environment: Application.get_env(:template_app, :env),
      node: Node.self()
    })

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TemplateAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
