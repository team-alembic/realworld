defmodule Realworld.Articles.ListArticlesTest do
  @moduledoc """
  Focused on the `read :list_articles` action — the app's article feed. It is
  the richest single action in the codebase and shows a lot of Ash at once:

    * a **custom read** with `argument`s (`filter`, `private_feed?`)
    * a **preparation** (`FilterSortFeed`) that sorts, filters and loads data
      differently depending on whether an actor is present
    * **offset pagination** (`Ash.Page.Offset` with `count`/`more?`)
    * the personalised feed via `exists(user.followers, ...)`

  Call convention (matching the LiveViews):

      Articles.list_articles(
        %{filter: %{tag: "elixir"}, private_feed?: false},
        page: [limit: 20, offset: 0],
        actor: current_user
      )
  """
  use Realworld.DataCase, async: true

  alias Realworld.Articles

  describe "default read (via the FilterSortFeed preparation)" do
    test "returns articles newest-first" do
      author = build_user()
      _a = build_article(author)
      _b = build_article(author)
      _c = build_article(author)

      {:ok, page} = Articles.list_articles(%{}, actor: author)
      created_ats = Enum.map(page.results, & &1.created_at)

      # The preparation prepends `sort([created_at: :desc])`.
      assert created_ats == Enum.sort(created_ats, {:desc, DateTime})
    end

    test "for an anonymous reader it loads user/tags/favorites_count but not is_favorited" do
      build_article(build_user())

      {:ok, page} = Articles.list_articles(%{}, actor: nil)
      article = hd(page.results)

      # The `%{actor: nil}` clause of the preparation loads these three...
      refute match?(%Ash.NotLoaded{}, article.user)
      refute match?(%Ash.NotLoaded{}, article.tags)
      refute match?(%Ash.NotLoaded{}, article.favorites_count)
      # ...but leaves the actor-specific calculation unloaded.
      assert match?(%Ash.NotLoaded{}, article.is_favorited)
    end

    test "for a signed-in reader it also loads the is_favorited calculation" do
      reader = build_user()
      build_article(build_user())

      {:ok, page} = Articles.list_articles(%{}, actor: reader)
      article = hd(page.results)

      assert is_boolean(article.is_favorited)
    end
  end

  describe "filter argument" do
    test "filters by tag" do
      author = build_user()
      tagged = build_article(author, tags: [%{name: "elixir"}])
      _untagged = build_article(author)

      {:ok, page} = Articles.list_articles(%{filter: %{tag: "elixir"}}, actor: author)

      assert Enum.map(page.results, & &1.id) == [tagged.id]
    end

    test "filters by author" do
      alice = build_user()
      bob = build_user()
      alice_article = build_article(alice)
      _bob_article = build_article(bob)

      {:ok, page} = Articles.list_articles(%{filter: %{author: alice.id}}, actor: alice)

      assert Enum.map(page.results, & &1.id) == [alice_article.id]
    end

    test "filters by favourited (note the British spelling the action expects)" do
      author = build_user()
      fan = build_user()
      favorited = build_article(author)
      _other = build_article(author)
      favorite_article(fan, favorited)

      {:ok, page} = Articles.list_articles(%{filter: %{favourited: fan.id}}, actor: fan)

      assert Enum.map(page.results, & &1.id) == [favorited.id]
    end

    test "an absent filter returns everything" do
      author = build_user()
      build_article(author)
      build_article(author)

      {:ok, page} = Articles.list_articles(%{}, actor: author)

      assert page.count == 2
    end
  end

  describe "offset pagination" do
    setup do
      author = build_user()
      for _ <- 1..25, do: build_article(author)
      %{author: author}
    end

    test "caps at the default limit of 20 and reports the total count", %{author: author} do
      {:ok, %Ash.Page.Offset{} = page} = Articles.list_articles(%{}, actor: author)

      assert length(page.results) == 20
      assert page.count == 25
      assert page.more? == true
    end

    test "offset walks to the next page", %{author: author} do
      {:ok, page} = Articles.list_articles(%{}, actor: author, page: [offset: 20])

      assert length(page.results) == 5
      assert page.more? == false
    end

    test "an explicit limit overrides the default", %{author: author} do
      {:ok, page} = Articles.list_articles(%{}, actor: author, page: [limit: 5])

      assert length(page.results) == 5
      assert page.count == 25
    end
  end

  describe "private feed (private_feed?: true)" do
    test "returns only articles from authors the reader follows" do
      reader = build_user()
      followed = build_user()
      unfollowed = build_user()

      followed_article = build_article(followed)
      _unfollowed_article = build_article(unfollowed)
      {:ok, _} = Realworld.Profiles.follow(followed.id, actor: reader)

      {:ok, page} =
        Articles.list_articles(%{private_feed?: true}, actor: reader)

      assert Enum.map(page.results, & &1.id) == [followed_article.id]
    end

    test "is empty when the reader follows nobody" do
      reader = build_user()
      build_article(build_user())

      {:ok, page} = Articles.list_articles(%{private_feed?: true}, actor: reader)

      assert page.results == []
    end

    test "private_feed? false (the default) ignores the follow graph" do
      reader = build_user()
      build_article(build_user())

      {:ok, page} = Articles.list_articles(%{private_feed?: false}, actor: reader)

      assert page.count == 1
    end
  end
end
