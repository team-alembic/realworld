defmodule Realworld.Articles.Favorite do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "favorites"
    repo Realworld.Repo
  end

  attributes do
    uuid_primary_key :id
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Realworld.Accounts.User do
      api Realworld.Accounts
      allow_nil? false
    end

    belongs_to :article, Realworld.Articles.Article do
      allow_nil? false
    end
  end
end
