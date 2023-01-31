defmodule Realworld.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  postgres do
    table "users"
    repo Realworld.Repo
  end

  actions do
    create :register do
      accept [:email, :username, :hashed_password]

      argument :email, :string do
        allow_nil? false
      end

      argument :username, :string do
        allow_nil? false
      end

      argument :hashed_password, :string do
        allow_nil? false
      end

      validate present(:email)
      validate present(:username)
      validate present(:hashed_password)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:email, :string, allow_nil?: false)
    attribute(:username, :string, allow_nil?: false)
    attribute(:hashed_password, :string, allow_nil?: false, sensitive?: true)
    attribute(:bio, :string)
    attribute(:image, :string)

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity :unique_email, [:email]
    identity :unique_username, [:username]
  end

  authentication do
    api Realworld.Accounts

    strategies do
      password :password do
        identity_field :email
      end
    end

    tokens do
      enabled? true
      token_resource Realworld.Accounts.Token

      signing_secret fn _, _ ->
        Application.get_env(:realworld, Realworld.Endpoint)[:secret_key_base]
      end
    end
  end
end
