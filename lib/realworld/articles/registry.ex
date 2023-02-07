defmodule Realworld.Articles.Registry do
  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry Realworld.Articles.Article
    entry Realworld.Articles.ArticleTag
    entry Realworld.Articles.Comment
    entry Realworld.Articles.Favorite
    entry Realworld.Articles.Tag
  end
end
