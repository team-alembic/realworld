defmodule Realworld.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    domain: Realworld.Accounts

  postgres do
    table "users"
    repo Realworld.Repo
  end

  code_interface do
    define :get_by_username, args: [:username]
  end

  actions do
    defaults [:read, :update]

    read :get_by_username do
      argument :username, :string do
        allow_nil? false
      end

      get? true

      filter expr(username == ^arg(:username))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string, allow_nil?: false, public?: true
    attribute :username, :string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :bio, :string, public?: true

    attribute :image, :string,
      default: "https://api.realworld.io/images/smiley-cyrus.jpeg",
      public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_email, [:email]
    identity :unique_username, [:username]
  end

  authentication do
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
