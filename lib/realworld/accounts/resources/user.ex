defmodule Realworld.Accounts.User do
  use Ash.Resource

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :bio, :string
    attribute :email, :string
    attribute :image, :string
    attribute :username, :string
    attribute :password, :string

    create_timestamp :created_at
    update_timestamp :updated_at
  end
end
