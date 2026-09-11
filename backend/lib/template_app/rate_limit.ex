defmodule TemplateApp.RateLimit do
  @moduledoc """
  Single-node ETS rate limiter for public authentication operations.

  ETS counters are local to one BEAM node. Multi-node deployments must route
  abuse controls through a shared limiter before relying on this boundary.
  """

  use Hammer, backend: :ets
end
