defmodule TemplateAppWeb.Plugs.CurrentUserPropPlug do
  @moduledoc """
  Injects current_user prop into Inertia pages automatically.
  """

  import Inertia.Controller

  alias TemplateAppWeb.Helpers.ConnHelpers
  alias TemplateAppWeb.Serializers.UserSerializer

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = ConnHelpers.get_current_user(conn)

    assign_prop(conn, :current_user, UserSerializer.serialize(current_user))
  end
end
