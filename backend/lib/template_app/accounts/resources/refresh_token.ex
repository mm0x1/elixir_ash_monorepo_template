defmodule TemplateApp.Accounts.Resources.RefreshToken do
  @moduledoc """
  Refresh token resource for hybrid token authentication.

  Each refresh token is stored in the database and associated with a user.
  The raw refresh secret is stored in an HttpOnly cookie on the client while
  only its SHA-256 digest is persisted.

  Token validation checks:
  1. Token exists in database
  2. Token version matches user.token_version (invalidated on "logout all")
  3. Token is not expired

  Tokens can be:
  - Deleted individually (single device logout)
  - Invalidated en masse by incrementing user.token_version (all devices logout)
  """

  use Ash.Resource,
    otp_app: :template_app,
    domain: TemplateApp.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAdmin.Resource]

  admin do
    read_actions []
    generic_actions []
    create_actions []
    update_actions []
    destroy_actions []
  end

  alias TemplateApp.Accounts.Changes.{GenerateRefreshSecret, SetTokenExpiry}

  @refresh_token_lifetime_days 7

  postgres do
    table "refresh_tokens"
    repo TemplateApp.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:device_name]

      argument :user_id, :uuid, allow_nil?: false
      # version must equal the user's current token_version so that logout_all
      # (which increments token_version) immediately invalidates all existing tokens.
      argument :version, :integer, allow_nil?: false

      change manage_relationship(:user_id, :user, type: :append)
      change GenerateRefreshSecret
      change set_attribute(:version, arg(:version))
      change {SetTokenExpiry, lifetime_days: @refresh_token_lifetime_days}

      # The raw secret is returned only by the issuance action and is never
      # populated by a database read.
      metadata :plain_refresh_secret, :string, allow_nil?: false
    end

    destroy :revoke do
      accept []
    end

    read :by_id do
      get? true
      argument :id, :uuid, allow_nil?: false
      filter expr(id == ^arg(:id))
    end

    read :by_secret_hash do
      get? true
      argument :secret_hash, :binary, allow_nil?: false, sensitive?: true
      filter expr(secret_hash == ^arg(:secret_hash))
    end

    read :by_user do
      argument :user_id, :uuid, allow_nil?: false
      filter expr(user_id == ^arg(:user_id))
    end
  end

  policies do
    # Users can only destroy their own tokens
    policy action([:destroy, :revoke]) do
      authorize_if relates_to_actor_via(:user)
    end

    # Read is internal only (for validation)
    policy action_type(:read), authorize_if: always()

    # Create is internal only (called from AuthController)
    policy action(:create), authorize_if: always()
  end

  attributes do
    uuid_primary_key :id

    attribute :secret_hash, :binary do
      allow_nil? false
      public? false
      sensitive? true
      writable? false
      description "SHA-256 digest of the refresh bearer secret"
    end

    attribute :device_name, :string do
      allow_nil? true
      public? true
      description "Optional device/browser name for display"
    end

    attribute :version, :integer do
      allow_nil? false
      default 1
      public? false

      description "Set to user.token_version at creation. Must still match user.token_version at refresh time; logout_all breaks this by incrementing token_version."
    end

    attribute :expires_at, :utc_datetime_usec do
      allow_nil? false
      public? false
    end

    timestamps()
  end

  relationships do
    belongs_to :user, TemplateApp.Accounts.Resources.User do
      allow_nil? false
    end
  end

  identities do
    identity :unique_secret_hash, [:secret_hash]
  end
end
