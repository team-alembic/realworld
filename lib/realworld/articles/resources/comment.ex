defmodule Realworld.Articles.Comment do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "comments"
    repo Realworld.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :add_comment do
      primary? true
      accept [:body]

      argument :article_id, :uuid do
        allow_nil? false
      end

      change relate_actor(:user)

      change manage_relationship(:article_id, :article, type: :append)
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
