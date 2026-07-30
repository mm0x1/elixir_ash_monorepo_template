defmodule TemplateAppWeb.HealthController do
  @moduledoc """
  Health check endpoint for load balancers and monitoring.
  """

  use TemplateAppWeb, :controller

  def index(conn, _params) do
    TemplateApp.Repo.query!("SELECT 1")
    json(conn, %{status: "ok"})
  end
end
