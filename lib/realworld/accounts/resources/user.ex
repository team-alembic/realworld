defmodule Realworld.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  postgres do
    table "users"
    repo Realworld.Repo
  end

  attributes do
    uuid_primary_key(:id)

    # attribute(:email, :string, allow_nil?: false)
    attribute(:username, :string, allow_nil?: false)
    attribute(:hashed_password, :string, allow_nil?: false, sensitive?: true)
    attribute(:bio, :string)
    attribute(:image, :string)

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  identities do
    # identity :unique_email, [:email]
    identity :unique_username, [:username]
  end

  authentication do
    api Realworld.Accounts

    strategies do
      password :password do
        identity_field :username
        hashed_password_field :hashed_password
        confirmation_required? false
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
