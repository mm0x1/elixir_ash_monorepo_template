defmodule TemplateAppWeb.ProductionRoutesTest do
  use ExUnit.Case, async: true

  @dev_routes Application.compile_env(:template_app, :dev_routes, false)

  test "development and admin routes are absent when dev routes are disabled" do
    paths = Enum.map(Phoenix.Router.routes(TemplateAppWeb.Router), & &1.path)

    refute Enum.any?(paths, &String.starts_with?(&1, "/dev"))
    refute Enum.any?(paths, &String.starts_with?(&1, "/admin"))
    refute Enum.any?(paths, &String.contains?(&1, "tidewave"))
    refute @dev_routes
  end
end
