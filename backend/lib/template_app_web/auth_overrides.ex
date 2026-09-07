defmodule TemplateAppWeb.AuthOverrides do
  @moduledoc false

  use AshAuthentication.Phoenix.Overrides

  alias AshAuthentication.Phoenix.Components

  override Components.Password do
    set :register_toggle_text, nil
  end

  override Components.Password.Input do
    set :identity_input_label, "Username"
    set :identity_input_placeholder, "admin"
  end
end
