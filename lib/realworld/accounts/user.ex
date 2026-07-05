defmodule Realworld.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Accounts

  postgres do
    table "users"
    repo Realworld.Repo
  end

  policies do
    # AshAuthentication's own machinery (loading the session user, token
    # operations) flags its requests with a private context; let those through
    # wholesale.
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    # The bypass does NOT cover our sign-in/registration UI: AuthLive submits
    # :register_with_password and :sign_in_with_password directly via
    # AshPhoenix.Form with a nil actor, so those need explicit anonymous
    # policies. Sign-in is a read, covered below.
    policy action(:register_with_password) do
      authorize_if always()
    end

    # Profiles are public, and sign-in itself is a read action.
    policy action_type(:read) do
      authorize_if always()
    end

    # Only you can change your own account.
    policy action_type(:update) do
      authorize_if expr(id == ^actor(:id))
    end
  end

  actions do
    defaults [:read]

    read :get_by_username do
      argument :username, :string do
        allow_nil? false
      end

      get? true

      filter expr(username == ^arg(:username))
    end

    update :update do
      primary? true
      require_atomic? false
      accept [:email, :username, :image, :bio]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string, allow_nil?: false, public?: true
    attribute :username, :string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :bio, :string, public?: true

    attribute :image, :string,
      default: "/images/smiley-cyrus.jpeg",
      public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_email, [:email]
    identity :unique_username, [:username]
  end

  relationships do
    has_many :followings, Realworld.Profiles.Follow

    has_many :followers, Realworld.Profiles.Follow do
      destination_attribute :target_id
    end
  end

  authentication do
    session_identifier :jti

    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password
        sign_in_tokens_enabled? true
        confirmation_required? false
        register_action_accept [:username]
      end
    end

    tokens do
      enabled? true
      token_resource Realworld.Accounts.Token

      signing_secret fn _, _ ->
        Application.fetch_env(:realworld, :token_signing_secret)
      end
    end
  end
end
