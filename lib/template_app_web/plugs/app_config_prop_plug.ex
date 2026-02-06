defmodule TemplateAppWeb.Plugs.AppConfigPropPlug do
  @moduledoc """
  Adds application configuration to Inertia props.

  This plug makes app config available to the frontend via Inertia props,
  creating a single source of truth (backend) for all configuration.

  The config is available in all Inertia pages via props.app_config.
  """
  import Plug.Conn
  alias TemplateApp.Config

  def init(opts), do: opts

  def call(conn, _opts) do
    assign_prop(conn, :app_config, %{
      name: Config.app_name(),
      description: Config.app_description(),
      company: Config.company_name(),
      url: Config.app_url(),
      theme: Config.default_theme(),
      features: %{
        registration: Config.registration_enabled?()
      }
    })
  end

  # Helper to assign Inertia props
  defp assign_prop(conn, key, value) do
    props = Map.get(conn.assigns, :inertia_props, %{})
    updated_props = Map.put(props, key, value)
    assign(conn, :inertia_props, updated_props)
  end
end
