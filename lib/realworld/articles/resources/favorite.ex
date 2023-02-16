defmodule Realworld.Articles.Favorite do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "favorites"
    repo Realworld.Repo

    references do
      reference :user, on_delete: :delete
      reference :article, on_delete: :delete
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:user)
    end
  end

  code_interface do
    define_for Realworld.Articles

    define :favorite, action: :add_favorite, args: [:article]
    define :unfavorite, action: :remove_favorite, args: [:article]
  end

  actions do
    create :add_favorite do
      primary? true

      argument :article, Realworld.Articles.Article, allow_nil?: false

      change relate_actor(:user)
      change manage_relationship(:article, type: :append)
    end

    destroy :remove_favorite do
      primary? true
    end
  end

  attributes do
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Realworld.Accounts.User do
      api Realworld.Accounts
      primary_key? true
      allow_nil? false
    end

    belongs_to :article, Realworld.Articles.Article do
      primary_key? true
      allow_nil? false
    end
  end
end
