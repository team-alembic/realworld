defmodule Realworld.Articles.ArticleTest do
  use Realworld.DataCase, async: true

  alias Realworld.Articles.Article

  test "publish article with slugified title" do
    actor = build_user()

    title = "How to test Ash resources #{System.unique_integer([:positive])}"

    {:ok, published_article} =
      Article
      |> Ash.Changeset.for_create(
        :publish,
        %{
          title: title,
          description: "An introduction to testing Ash",
          body_raw: "Some article body."
        },
        actor: actor
      )
      |> Ash.create()

    assert published_article.title == title
    assert published_article.slug == Slug.slugify(title)
  end
end
