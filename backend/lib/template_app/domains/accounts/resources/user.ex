defmodule TemplateApp.Domains.Accounts.Resources.User do
  @moduledoc """
  User resource with support for password authentication, recovery codes, and anonymous users.
  """

  use Ash.Resource,
    otp_app: :template_app,
    domain: TemplateApp.Domains.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication, AshPhoenix, AshTypescript.Resource]

  alias TemplateApp.Domains.Accounts.Changes.{
    GenerateAnonymousUser,
    GenerateRecoveryCodes,
    ConsumeRecoveryCodeAndResetPassword,
    SetUsernameLastChanged
  }

  alias TemplateApp.Domains.Accounts.Validations.{
    UsernameChangeRateLimit,
    ValidateRecoveryCode
  }

  require Ash.Query

  authentication do
    session_identifier :jti

    tokens do
      enabled? true
      token_resource TemplateApp.Domains.Accounts.Resources.Token
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
  end

  typescript do
    type_name("User")
  end

  actions do
    defaults [:read, :update]

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
        constraints: [min_length: 8],
        sensitive?: true

      argument :password_confirmation, :string, allow_nil?: false, sensitive?: true

      change set_attribute(:username, arg(:username))
      change AshAuthentication.Strategy.Password.HashPasswordChange
      change AshAuthentication.GenerateTokenChange

      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

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
    end

    update :reset_password_with_recovery_code do
      require_atomic? false

      argument :recovery_code, :string, allow_nil?: false, sensitive?: true
      argument :new_password, :string, allow_nil?: false, sensitive?: true

      validate ValidateRecoveryCode
      change ConsumeRecoveryCodeAndResetPassword
    end

    update :convert_to_registered do
      require_atomic? false

      argument :username, :ci_string, allow_nil?: false
      argument :password, :string, allow_nil?: false, sensitive?: true
      argument :password_confirmation, :string, allow_nil?: false, sensitive?: true

      validate attribute_equals(:is_anonymous, true) do
        message "only anonymous users can convert to registered"
      end

      validate fn changeset, _ctx ->
        pw = Ash.Changeset.get_argument(changeset, :password)
        confirm = Ash.Changeset.get_argument(changeset, :password_confirmation)

        if pw == confirm,
          do: :ok,
          else: {:error, field: :password_confirmation, message: "does not match"}
      end

      validate fn changeset, _ctx ->
        if String.length(Ash.Changeset.get_argument(changeset, :password) || "") >= 8 do
          :ok
        else
          {:error, field: :password, message: "must be at least 8 characters"}
        end
      end

      change fn changeset, _ctx ->
        password = Ash.Changeset.get_argument(changeset, :password)
        username = Ash.Changeset.get_argument(changeset, :username)

        changeset
        |> Ash.Changeset.change_attribute(:username, username)
        |> Ash.Changeset.change_attribute(:hashed_password, Argon2.hash_pwd_salt(password))
        |> Ash.Changeset.change_attribute(:is_anonymous, false)
      end
    end

    update :change_username do
      require_atomic? false
      accept [:username]

      validate present(:username)

      validate match(:username, ~r/^[a-zA-Z0-9_]{3,30}$/) do
        message "must be 3-30 characters, letters, numbers, underscore only"
      end

      validate UsernameChangeRateLimit
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
              expr(fragment("array_length(?, 1) > 0", recovery_codes)) do
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
