defmodule Realworld.Articles do
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Articles.Article
    resource Realworld.Articles.ArticleTag
    resource Realworld.Articles.Comment
    resource Realworld.Articles.Favorite
    resource Realworld.Articles.Tag
  end
end
