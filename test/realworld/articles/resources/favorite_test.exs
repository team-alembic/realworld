defmodule Realworld.Articles.FavoriteTest do
  @moduledoc """
  Exercises the `Favorite` resource (favoriting articles) and demonstrates:

    * **upsert** creates (`add_favorite`) that are idempotent per (user, article)
    * detecting "was this a fresh favorite?" via `created_at == updated_at`
    * **`get?` reads** (`favorited`) returning a record, a NotFound error
      (surfaced wrapped in the `Ash.Error.Invalid` error class), or
      `{:ok, nil}` with `not_found_error?: false`
    * destroys scoped to the actor through `change filter(...)`
    * reading the `favorites_count` **aggregate** with `Ash.load!/2`
  """
  use Realworld.DataCase, async: true

  alias Realworld.Articles
  alias Realworld.Articles.Favorite

  describe "favorite/2 (create :add_favorite)" do
    test "favorites an article for the current actor" do
      author = build_user()
      reader = build_user()
      article = build_article(author)

      # Code interface: `define :favorite, action: :add_favorite, args: [:article_id]`.
      assert {:ok, favorite} = Articles.favorite(article.id, actor: reader)
      assert favorite.user_id == reader.id
      assert favorite.article_id == article.id
    end

    test "favoriting twice is idempotent (upsert on :unique_favorite)" do
      article = build_article(build_user())
      reader = build_user()

      {:ok, first} = Articles.favorite(article.id, actor: reader)
      {:ok, second} = Articles.favorite(article.id, actor: reader)

      # `upsert? true` means the second call updates the existing row. On a
      # fresh insert `created_at == updated_at`; after an upsert they differ —
      # this is exactly how the LiveView tells a new favorite from a repeat.
      assert first.created_at == first.updated_at
      assert second.updated_at >= second.created_at
      assert Ash.count!(Favorite) == 1
    end

    test "requires an actor" do
      article = build_article(build_user())

      # `relate_actor(:user)` cannot resolve without an actor, so this is an
      # Invalid error (the `:user` relationship is required).
      assert {:error, %Ash.Error.Invalid{}} = Articles.favorite(article.id)
    end
  end

  describe "favorited/2 (read :favorited, get? true)" do
    test "returns the favorite for the actor, NotFound (or nil) otherwise" do
      article = build_article(build_user())
      reader = build_user()

      # No match on a `get?` read is an `Ash.Error.Query.NotFound`, wrapped in
      # the `Ash.Error.Invalid` error class.
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Articles.favorited(article.id, actor: reader)

      {:ok, _} = Articles.favorite(article.id, actor: reader)

      assert {:ok, %Favorite{} = fav} = Articles.favorited(article.id, actor: reader)
      assert fav.article_id == article.id

      # Another user has not favorited it; ask for nil instead of an error.
      other = build_user()
      assert {:ok, nil} = Articles.favorited(article.id, actor: other, not_found_error?: false)
    end
  end

  describe "unfavorite/2 (destroy :remove_favorite) and favorites_count" do
    test "removes only the actor's favorite and the aggregate follows" do
      article = build_article(build_user())
      alice = build_user()
      bob = build_user()

      favorite_article(alice, article)
      favorite_article(bob, article)

      # The `count :favorites_count, :favorites` aggregate is derived data,
      # loaded on demand rather than stored.
      assert Ash.load!(article, :favorites_count).favorites_count == 2

      # `change filter(user_id == ^actor(:id) and article_id == ^arg(...))`
      # scopes the destroy to Alice's own favorite.
      assert {:ok, _} = Articles.unfavorite(article.id, actor: alice, return_destroyed?: true)

      assert Ash.load!(article, :favorites_count).favorites_count == 1
      assert {:ok, nil} = Articles.favorited(article.id, actor: alice, not_found_error?: false)
      assert {:ok, %Favorite{}} = Articles.favorited(article.id, actor: bob)
    end
  end
end
