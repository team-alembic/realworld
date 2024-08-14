defmodule Realworld.Articles do
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
