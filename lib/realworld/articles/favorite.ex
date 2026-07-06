defmodule Realworld.Articles.Favorite do
  @moduledoc """
  A user's favorite of an article — a join between User and Article whose
  composite primary key is the two foreign keys (no surrogate id).

  Worth reading for:

    * an **idempotent upsert** create (`upsert_identity :unique_favorite`) —
      favoriting twice updates the same row
    * actor-scoped reads and destroys via `^actor(:id)` in filters, so a user
      can only see "did *I* favorite this?" and remove their own favorite
    * PubSub broadcasts that keep favorite counters live across open pages

  `Realworld.Articles.FavoriteTest` walks through all three.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: Realworld.Articles

  resource do
    description "A user's favorite of an article; the composite primary key is (user_id, article_id)."
  end

  postgres do
    table "favorites"
    repo Realworld.Repo

    references do
      reference :user, on_delete: :delete
      reference :article, on_delete: :delete
    end
  end

  pub_sub do
    module RealworldWeb.Endpoint
    prefix "favorite"

    publish_all :create, ["created", :article_id]
    publish_all :destroy, ["destroyed", :article_id]
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

  actions do
    defaults [:read]

    read :favorited do
      description "Did the actor favorite this article? A get? read scoped to the actor."
      get? true

      argument :article_id, :uuid, allow_nil?: false

      filter expr(user_id == ^actor(:id) and article_id == ^arg(:article_id))
    end

    create :add_favorite do
      description "Favorite an article as the actor — idempotent thanks to the upsert."
      primary? true
      upsert? true
      upsert_identity :unique_favorite

      accept [:article_id]

      change relate_actor(:user)
    end

    destroy :remove_favorite do
      description "Remove the actor's own favorite of an article."
      primary? true
      argument :article_id, :uuid, allow_nil?: false
      change filter(expr(article_id == ^arg(:article_id)))
      change filter(expr(user_id == ^actor(:id)))
    end
  end

  attributes do
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_favorite, [:user_id, :article_id]
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
