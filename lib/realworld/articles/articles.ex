defmodule Realworld.Articles do
  @moduledoc """
  The Articles domain: publishing, tagging, commenting on and favoriting
  articles.

  The `define` blocks below build the domain's **code interface** — plain
  functions like `Articles.list_articles/2` and `Articles.favorite/2` that the
  web layer calls instead of building `Ash.Query`/`Ash.Changeset` by hand.
  Every call accepts an `actor:` option, and `authorize :by_default` means
  each resource's policies always run.
  """
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Articles.Article do
      define :get_article_by_slug, action: :read, get_by: :slug
      define :list_articles
      define :destroy_article, action: :destroy
    end

    resource Realworld.Articles.ArticleTag

    resource Realworld.Articles.Comment do
      define :destroy_comment, action: :destroy
    end

    resource Realworld.Articles.Favorite do
      define :favorite, action: :add_favorite, args: [:article_id]

      define :unfavorite,
        action: :remove_favorite,
        args: [:article_id],
        require_reference?: false,
        get?: true

      define :favorited, action: :favorited, args: [:article_id]
    end

    resource Realworld.Articles.Tag
  end
end
