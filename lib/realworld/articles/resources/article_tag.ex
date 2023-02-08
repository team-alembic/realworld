defmodule Realworld.Articles.ArticleTag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "article_tags"
    repo Realworld.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id
  end

  relationships do
    belongs_to :article, Realworld.Articles.Article do
      allow_nil? false
    end

    belongs_to :tag, Realworld.Articles.Tag do
      allow_nil? false
    end
  end
end
