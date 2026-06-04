defmodule TemplateApp.Accounts do
  @moduledoc """
  Domain for user authentication.
  """

  use Ash.Domain,
    otp_app: :template_app,
    extensions: [AshAdmin.Domain, AshPhoenix, AshOps]

  alias TemplateApp.Accounts.Resources.User
  alias TemplateApp.Accounts.Resources.Token
  alias TemplateApp.Accounts.Resources.RefreshToken

  admin do
    show? true
  end

  resources do
    resource User do
      define :create_user,
        args: [:username, :password, :password_confirmation],
        action: :register_with_password

      define :get_by_username,
        args: [:username],
        action: :by_username

      define :get_user_by_id,
        args: [:id],
        action: :by_id

      define :sign_in,
        args: [:username, :password],
        action: :sign_in_with_password

      define :create_anonymous,
        action: :create_anonymous

      define :generate_recovery_codes,
        action: :generate_recovery_codes

      define :request_password_reset,
        action: :request_password_reset

      define :reset_password_with_recovery_code,
        args: [:recovery_code, :new_password],
        action: :reset_password_with_recovery_code

      define :convert_to_registered,
        args: [:username, :password, :password_confirmation],
        action: :convert_to_registered

      define :change_username,
        args: [:username],
        action: :change_username
    end

    resource Token

    resource RefreshToken do
      define :get_refresh_token_by_id,
        args: [:id],
        action: :by_id

      define :get_refresh_tokens_for_user,
        args: [:user_id],
        action: :by_user
    end
  end
end
