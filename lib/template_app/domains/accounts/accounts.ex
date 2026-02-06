defmodule TemplateApp.Domains.Accounts do
  @moduledoc """
  Domain for user authentication.
  """

  use Ash.Domain,
    otp_app: :template_app,
    extensions: [AshAdmin.Domain, AshPhoenix, AshOps, AshTypescript.Rpc]

  alias TemplateApp.Domains.Accounts.Resources.User
  alias TemplateApp.Domains.Accounts.Resources.Token

  admin do
    show? true
  end

  typescript_rpc do
    namespace "accounts"

    resource User do
      typed_query :current_user, :read do
        description "Current user shape for Inertia page props"
        ts_result_type_name "CurrentUser"
        ts_fields_const_name "CURRENT_USER_FIELDS"
        fields [:id, :username, :is_anonymous, :role, :has_recovery_codes, :recovery_codes_count]
      end

      rpc_action :get_user, :by_id do
        get? true
        denied_loads [:recovery_codes, :hashed_password, :recovery_codes_generated_at, :username_last_changed]
      end

      rpc_action :change_username, :change_username do
        denied_loads [:recovery_codes, :hashed_password, :recovery_codes_generated_at, :username_last_changed]
      end
    end
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
  end
end
