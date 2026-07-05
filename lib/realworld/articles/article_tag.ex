defmodule Realworld.Articles.ArticleTag do
  @moduledoc """
  The join resource between Article and Tag.

  Deliberately has no policies: it is only ever written through Article's
  policy-guarded `manage_relationship` (`:publish`/`:update`), and Article's
  `on_missing: :unrelate` destroys rows here — naive destroy policies would
  break article updates without adding any safety.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Realworld.Articles

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
    defaults [:create, :read, :destroy]
  end

  relationships do
    belongs_to :article, Article, primary_key?: true, allow_nil?: false
    belongs_to :tag, Tag, primary_key?: true, allow_nil?: false
  end
end
