defmodule RealworldWeb.ArticleLiveTest do
  @moduledoc """
  LiveView tests for the article page (`ArticleLive.Index`). Data is seeded
  through domain actions, then we drive the page with `PhoenixTest` and assert
  on what it renders.
  """
  use RealworldWeb.ConnCase, async: false

  alias Realworld.Articles.Comment

  defp seed_comment(article, user, body) do
    Comment
    |> Ash.Changeset.for_create(:create, %{body: body, article_id: article.id}, actor: user)
    |> Ash.create!()
  end

  test "renders the article title, rendered body and tags", %{conn: conn} do
    author = build_user()

    article =
      build_article(author,
        title: "Understanding Ash Policies",
        body_raw: "Some **important** content.",
        tags: [%{name: "ash"}]
      )

    conn
    |> visit(~p"/article/#{article.slug}")
    |> assert_has("h1", text: "Understanding Ash Policies")
    # `body` is markdown rendered to HTML inside <article>.
    |> assert_has("article", text: "important")
    |> assert_has(".tag-list", text: "ash")
  end

  test "shows existing comments", %{conn: conn} do
    author = build_user()
    commenter = build_user()
    article = build_article(author)
    seed_comment(article, commenter, "This helped me a lot!")

    conn
    |> visit(~p"/article/#{article.slug}")
    |> assert_has(".card-text", text: "This helped me a lot!")
  end

  test "guests are prompted to sign in before commenting", %{conn: conn} do
    article = build_article(build_user())

    conn
    |> visit(~p"/article/#{article.slug}")
    |> assert_has("p", text: "to add comments", exact: false)
  end
end
