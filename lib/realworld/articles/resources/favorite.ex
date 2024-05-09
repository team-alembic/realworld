defmodule Realworld.Articles.Favorite do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Articles

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
    define :favorite, action: :add_favorite, args: [:article]
    define :unfavorite, action: :remove_favorite, args: [:article]
    define :favorited, action: :favorited, args: [:article_id]
  end

  actions do
    defaults [:read]

    read :favorited do
      get? true

      argument :article_id, :uuid, allow_nil?: false

      filter expr(user_id == ^actor(:id) and article_id == ^arg(:article_id))
    end

    create :add_favorite do
      primary? true

      argument :article, :struct,
        allow_nil?: false,
        constraints: [instance_of: Realworld.Articles.Article]

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
      primary_key? true
      allow_nil? false
    end

    belongs_to :article, Realworld.Articles.Article do
      primary_key? true
      allow_nil? false
    end
  end
end
