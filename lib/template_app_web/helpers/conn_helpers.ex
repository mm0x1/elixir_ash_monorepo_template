defmodule TemplateAppWeb.Helpers.ConnHelpers do
  @moduledoc """
  Helpers for extracting data from Plug.Conn structs.
  """

  @spec get_current_user(Plug.Conn.t()) :: map() | nil
  def get_current_user(%Plug.Conn{} = conn), do: conn.assigns[:current_user]
end
