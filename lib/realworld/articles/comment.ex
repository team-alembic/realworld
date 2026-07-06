defmodule Realworld.Articles.Comment do
  @moduledoc """
  A comment on an article. Demonstrates two things beyond the usual policies:

    * `Ash.Notifier.PubSub` — creates and destroys broadcast on
      `"comment:created:<article_id>"` / `"comment:destroyed:<article_id>"`,
      which `ArticleLive` subscribes to so open article pages update live
    * an argument-driven read (`:comments_by_article`) filtered with
      `expr(article_id == ^arg(:article_id))`
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: Realworld.Articles

  resource do
    description "A user's comment on an article."
  end

  postgres do
    table "comments"
    repo Realworld.Repo
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

  pub_sub do
    module RealworldWeb.Endpoint
    prefix "comment"

    publish :create, ["created", :article_id]
    publish :destroy, ["destroyed", :article_id]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "Post a comment on an article as the actor."
      primary? true
      accept [:body]

      argument :article_id, :uuid do
        description "The article being commented on."
        allow_nil? false
      end

      change relate_actor(:user)

      change manage_relationship(:article_id, :article, type: :append)
    end

    read :comments_by_article do
      description "All comments on one article."

      argument :article_id, :uuid do
        allow_nil? false
      end

      filter expr(article_id == ^arg(:article_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :body, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :article, Realworld.Articles.Article do
      allow_nil? false
    end

    belongs_to :user, Realworld.Accounts.User
  end
end
