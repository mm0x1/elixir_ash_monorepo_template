defmodule TemplateAppWeb.RpcController do
  @moduledoc """
  Controller for ash_typescript RPC endpoints.

  Handles typed RPC requests from the generated TypeScript client,
  providing type-safe data fetching for client-side interactions.
  """

  use TemplateAppWeb, :controller

  def run(conn, params) do
    result = AshTypescript.Rpc.run_action(:template_app, conn, params)
    json(conn, result)
  end

  def validate(conn, params) do
    result = AshTypescript.Rpc.validate_action(:template_app, conn, params)
    json(conn, result)
  end
end
