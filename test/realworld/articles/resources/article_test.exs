defmodule Realworld.Articles.ArticleTest do
  use Realworld.DataCase, async: true

  alias Realworld.Articles.Article

  test "publish article with slugified title" do
    actor = build_user()

    title = Faker.Lorem.words(10) |> Enum.join(" ")

    {:ok, published_article} =
      Article
      |> Ash.Changeset.for_create(
        :publish,
        %{
          title: title,
          description: Faker.Lorem.sentence(10),
          body_raw: Faker.Lorem.paragraph(5)
        },
        actor: actor
      )
      |> Ash.create()

    assert published_article.title == title
    assert published_article.slug == Slug.slugify(title)
  end
end
