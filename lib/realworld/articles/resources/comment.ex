defmodule Realworld.Articles.Comment do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "comments"
    repo Realworld.Repo
  end

  actions do
    defaults [:create, :read, :destroy]

    create :add_comment_to_article do
      accept [:body]

      argument :article_id, :uuid do
        allow_nil? false
      end

      argument :user_id, :uuid do
        allow_nil? false
      end

      change manage_relationship(:article_id, :article, type: :append)
      change manage_relationship(:user_id, :user, type: :append)
    end

    read :comments_by_article do
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
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :article, Realworld.Articles.Article do
      allow_nil? false
    end

    belongs_to :user, Realworld.Accounts.User do
      api Realworld.Accounts
    end
  end
end
