defmodule RealworldWeb.ArticleLiveTest do
  @moduledoc """
  LiveView tests for the article page (`ArticleLive.Index`). Data is seeded
  through domain actions, then we drive the page with `PhoenixTest` and assert
  on what it renders.

  The comment form's inputs are placeholder-only (no `<label>`s yet), and
  `PhoenixTest.fill_in/3` targets inputs by label — so form submissions here
  drop down to `Phoenix.LiveViewTest` via `unwrap/2`, PhoenixTest's escape
  hatch. `unwrap` hands us the underlying LiveView and re-integrates the
  result (following any redirect) back into the session.
  """
  use RealworldWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Realworld.Articles.Comment

  defp seed_comment(article, user, body) do
    Comment
    |> Ash.Changeset.for_create(:create, %{body: body, article_id: article.id}, actor: user)
    |> Ash.create!()
  end

  defp submit_comment(session, body) do
    unwrap(session, fn view ->
      view
      |> form("form.comment-form", %{"comment" => %{"body" => body}})
      |> render_submit()
    end)
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

  describe "as a signed-in user" do
    setup :register_and_log_in_user

    test "posting a comment renders it and clears the form", %{conn: conn} do
      article = build_article(build_user())

      conn
      |> visit(~p"/article/#{article.slug}")
      |> submit_comment("Great article!")
      # The new comment arrives back via the PubSub broadcast the page is
      # subscribed to ("comment:created:<article_id>").
      |> assert_has(".card-text", text: "Great article!")
      # On success the component resets to a fresh form, so the textarea
      # no longer holds the submitted text.
      |> refute_has("textarea", text: "Great article!")
    end

    test "an empty comment shows a validation error", %{conn: conn} do
      article = build_article(build_user())

      conn
      |> visit(~p"/article/#{article.slug}")
      |> submit_comment("")
      # Comment's `body` is `allow_nil? false`; the error form renders via
      # `error_tag/2`.
      |> assert_has("span", text: "is required")
      |> refute_has(".card-text", text: "is required")
    end

    test "deleting your own comment removes it", %{conn: conn, user: user} do
      article = build_article(build_user())
      seed_comment(article, user, "Delete me please")

      conn
      |> visit(~p"/article/#{article.slug}")
      |> assert_has(".card-text", text: "Delete me please")
      # The trash icon is a phx-click, not a button/link, so click it via the
      # underlying LiveView. Removal renders through the "comment:destroyed"
      # PubSub broadcast.
      |> unwrap(fn view ->
        view |> element("i.ion-trash-a") |> render_click()
      end)
      |> refute_has(".card-text", text: "Delete me please")
    end

    test "an article you favorited shows the unfavorite button", %{conn: conn, user: user} do
      article = build_article(build_user())
      favorite_article(user, article)

      # Regression: the page used to look favorited state up without an actor,
      # so this button never rendered for anyone.
      conn
      |> visit(~p"/article/#{article.slug}")
      |> assert_has("button", text: "Unfavorite Article")
    end
  end
end
