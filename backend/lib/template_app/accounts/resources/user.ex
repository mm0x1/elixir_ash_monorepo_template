defmodule TemplateApp.Accounts.Resources.User do
  @moduledoc """
  User resource with support for password authentication, recovery codes, and anonymous users.
  """

  use Ash.Resource,
    otp_app: :template_app,
    domain: TemplateApp.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAdmin.Resource, AshAuthentication, AshPhoenix]

  admin do
    # The local admin surface is intentionally read-only. Passwords, recovery
    # codes, sessions, and role changes stay outside this browser UI.
    read_actions [:read]
    generic_actions []
    create_actions []
    update_actions []
    destroy_actions []
  end

  alias TemplateApp.Accounts.Changes.{
    ConvertToRegistered,
    GenerateAnonymousUser,
    GenerateRecoveryCodes,
    ConsumeRecoveryCodeAndResetPassword,
    SetUsernameLastChanged
  }

  alias TemplateApp.Accounts.Validations.{
    UsernameChangeRateLimit,
    ValidateUsername,
    ValidatePasswordPolicy,
    ValidateRecoveryCode
  }

  authentication do
    session_identifier :jti

    tokens do
      enabled? true
      token_resource TemplateApp.Accounts.Resources.Token
      signing_secret TemplateApp.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
      token_lifetime {30, :days}
    end

    strategies do
      password :password do
        identity_field :username
        password_field :password
        password_confirmation_field :password_confirmation
        hashed_password_field :hashed_password
        hash_provider AshAuthentication.Argon2Provider
        sign_in_tokens_enabled? false
        confirmation_required? true
      end
    end
  end

  postgres do
    table "users"
    repo TemplateApp.Repo

    check_constraints do
      check_constraint :role, "users_role_is_valid",
        check: "role IN ('user', 'admin', 'superadmin')",
        message: "is invalid"

      check_constraint :token_version, "users_token_version_positive",
        check: "token_version > 0",
        message: "must be positive"
    end
  end

  actions do
    defaults [:read]

    read :by_id do
      description "Load user by ID"
      get? true
      argument :id, :uuid, allow_nil?: false
      filter expr(id == ^arg(:id))
    end

    read :by_username do
      get? true
      argument :username, :ci_string, allow_nil?: false
      filter expr(username == ^arg(:username))
    end

    create :register_with_password do
      argument :username, :ci_string, allow_nil?: false

      argument :password, :string,
        allow_nil?: false,
        sensitive?: true

      argument :password_confirmation, :string, allow_nil?: false, sensitive?: true

      change set_attribute(:username, arg(:username))
      change AshAuthentication.Strategy.Password.HashPasswordChange
      change AshAuthentication.GenerateTokenChange

      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation
      validate {ValidatePasswordPolicy, [argument: :password]}
      validate {ValidateUsername, [argument: :username]}

      metadata :token, :string, allow_nil?: false
    end

    create :create_anonymous do
      accept []
      change GenerateAnonymousUser
    end

    update :generate_recovery_codes do
      require_atomic? false
      accept []

      validate attribute_does_not_equal(:is_anonymous, true) do
        message "anonymous users cannot have recovery codes"
      end

      change GenerateRecoveryCodes

      # Plain codes are returned once here; the attribute stores only hashed versions.
      metadata :plain_recovery_codes, {:array, :string}, allow_nil?: false
    end

    update :reset_password_with_recovery_code do
      # The domain interface wraps this action in Ash.transact/3. The explicit
      # transaction setting keeps the lock and all session revocations together.
      transaction? true
      require_atomic? false

      argument :recovery_code, :string, allow_nil?: false, sensitive?: true
      argument :new_password, :string, allow_nil?: false, sensitive?: true

      validate ValidateRecoveryCode
      validate {ValidatePasswordPolicy, [argument: :new_password]}
      change get_and_lock_for_update()
      change ConsumeRecoveryCodeAndResetPassword
    end

    update :convert_to_registered do
      require_atomic? false

      argument :username, :ci_string, allow_nil?: false

      argument :password, :string,
        allow_nil?: false,
        sensitive?: true

      argument :password_confirmation, :string, allow_nil?: false, sensitive?: true

      validate attribute_equals(:is_anonymous, true) do
        message "only anonymous users can convert to registered"
      end

      validate {ValidateUsername, [argument: :username]}
      validate {ValidatePasswordPolicy, [argument: :password]}
      change ConvertToRegistered
    end

    update :change_username do
      transaction? true
      require_atomic? false
      accept [:username]

      validate {ValidateUsername, [attribute: :username]}
      validate UsernameChangeRateLimit
      change get_and_lock_for_update()
      change SetUsernameLastChanged
    end

    # Increment token_version to invalidate all refresh tokens (logout all devices)
    update :increment_token_version do
      accept []
      change atomic_update(:token_version, expr(token_version + 1))
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read), authorize_if: always()
    policy action(:register_with_password), authorize_if: always()
    policy action(:create_anonymous), authorize_if: always()
    policy action(:reset_password_with_recovery_code), authorize_if: always()

    policy action([
             :generate_recovery_codes,
             :convert_to_registered,
             :change_username,
             :increment_token_version
           ]) do
      authorize_if expr(id == ^actor(:id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :username, :ci_string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: true, sensitive?: true

    attribute :is_anonymous, :boolean, default: false, allow_nil?: false, public?: true

    attribute :role, :atom do
      allow_nil? false
      default :user
      public? true
      constraints one_of: [:user, :admin, :superadmin]
    end

    attribute :recovery_codes, {:array, :string}, default: [], sensitive?: true
    attribute :recovery_codes_generated_at, :utc_datetime_usec

    attribute :username_last_changed, :utc_datetime_usec, allow_nil?: true, public?: false

    # Token version for invalidating all refresh tokens at once (logout all devices)
    attribute :token_version, :integer, default: 1, allow_nil?: false, public?: false

    timestamps()
  end

  calculations do
    calculate :has_recovery_codes,
              :boolean,
              expr(fragment("coalesce(array_length(?, 1) > 0, false)", recovery_codes)) do
      public? true
    end

    calculate :recovery_codes_count,
              :integer,
              expr(fragment("coalesce(array_length(?, 1), 0)", recovery_codes)) do
      public? true
    end
  end

  identities do
    identity :unique_username, [:username]
  end
end
