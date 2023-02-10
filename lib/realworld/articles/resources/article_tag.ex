defmodule Realworld.Articles.ArticleTag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  alias Realworld.Articles.Article
  alias Realworld.Articles.Tag

  postgres do
    table "article_tags"
    repo Realworld.Repo

    references do
      reference :article, on_delete: :delete
      reference :tag, on_delete: :delete
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  relationships do
    belongs_to :article, Article, primary_key?: true, allow_nil?: false
    belongs_to :tag, Tag, primary_key?: true, allow_nil?: false
  end
end
