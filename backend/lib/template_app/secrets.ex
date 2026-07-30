defmodule TemplateApp.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        TemplateApp.Accounts.Resources.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:template_app, :ash_auth_signing_secret)
  end
end
