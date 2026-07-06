defmodule Realworld.Accounts.User do
  @moduledoc """
  A user account. The `AshAuthentication` extension supplies the password
  strategy's register/sign-in actions and token handling (`session_identifier
  :jti` lets sign-out revoke tokens); this module only declares the profile
  attributes, identities and policies around them.

  The policy block is the most instructive part: it shows the split between
  the `AshAuthenticationInteraction` bypass (for the library's internal calls)
  and the explicit anonymous policies our own sign-in/registration UI needs.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Accounts

  resource do
    description "A registered user account with a public profile."
  end

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
      description "Look one user up by username, as the profile pages do."

      argument :username, :string do
        allow_nil? false
      end

      get? true

      filter expr(username == ^arg(:username))
    end

    update :update do
      description "Update your own profile — the update policy restricts this to the actor themselves."
      primary? true
      require_atomic? false
      accept [:email, :username, :image, :bio]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string, allow_nil?: false, public?: true
    attribute :username, :string, allow_nil?: false, public?: true

    attribute :hashed_password, :string,
      allow_nil?: false,
      sensitive?: true,
      description: "Password hash managed by AshAuthentication — the plaintext is never stored."

    attribute :bio, :string, public?: true

    attribute :image, :string,
      default: "/images/smiley-cyrus.jpeg",
      public?: true,
      description: "Profile picture URL; defaults to the locally served smiley avatar."

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
