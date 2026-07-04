defmodule Realworld.Articles.ArticleTest do
  @moduledoc """
  Exercises the `Article` resource end to end and serves as the main worked
  example for the Articles domain. Concepts demonstrated:

    * `create`/`update` actions driven by custom `change` modules
      (`SlugifyTitle`, `RenderMarkdown`) and `relate_actor/1`
    * `manage_relationship` for tags (`on_lookup`/`on_no_match`/`on_missing`)
    * author-only `update`/`destroy` policies (`relates_to_actor_via`)
    * checking a policy without running the action via `Ash.can?/2`
    * loading a `count` aggregate (`favorites_count`) and a `calculate`
      with a required argument (`is_favorited`)
    * the Forbidden (policy) vs Invalid (validation) error distinction
  """
  use Realworld.DataCase, async: true

  alias Realworld.Articles
  alias Realworld.Articles.{Article, Tag}

  # Actions with no code interface are called via a changeset — the explicit,
  # mechanics-visible style (contrast with `Articles.favorite/2` etc).
  defp publish(actor, attrs) do
    Article
    |> Ash.Changeset.for_create(:publish, attrs, actor: actor)
    |> Ash.create()
  end

  defp uniq, do: System.unique_integer([:positive])

  describe "publish (create :publish)" do
    test "publish article with slugified title" do
      actor = build_user()

      title = "How to test Ash resources #{uniq()}"

      {:ok, published_article} =
        publish(actor, %{
          title: title,
          description: "An introduction to testing Ash",
          body_raw: "Some article body."
        })

      # `SlugifyTitle` derives the slug from the title.
      assert published_article.title == title
      assert published_article.slug == Slug.slugify(title)
    end

    test "renders body_raw markdown into sanitized HTML" do
      actor = build_user()

      {:ok, article} =
        publish(actor, %{
          title: "Markdown #{uniq()}",
          description: "d",
          body_raw: "# Heading\n\nsome **bold** text"
        })

      # `RenderMarkdown` populates `body` from `body_raw`.
      assert article.body =~ "<h1>"
      assert article.body =~ "<strong>"
      # Raw HTML is sanitized away.
      refute article.body =~ "<script>"
    end

    test "relates the actor as the author" do
      actor = build_user()

      {:ok, article} =
        publish(actor, %{title: "Authored #{uniq()}", description: "d", body_raw: "b"})

      article = Ash.load!(article, :user)
      assert article.user.id == actor.id
    end

    test "requires an actor" do
      # `relate_actor/1` defaults to `allow_nil?: false`, so no actor -> Invalid.
      assert {:error, %Ash.Error.Invalid{}} =
               publish(nil, %{title: "t #{uniq()}", description: "d", body_raw: "b"})
    end

    test "requires a title (Invalid, not Forbidden)" do
      actor = build_user()
      # Missing a required attribute is a validation failure.
      assert {:error, %Ash.Error.Invalid{}} =
               publish(actor, %{description: "d", body_raw: "b"})
    end
  end

  describe "tags via manage_relationship" do
    test "new tags are created (on_no_match: :create)" do
      actor = build_user()

      {:ok, article} =
        publish(actor, %{
          title: "Tagged #{uniq()}",
          description: "d",
          body_raw: "b",
          tags: [%{name: "elixir"}, %{name: "ash"}]
        })

      article = Ash.load!(article, :tags)
      assert Enum.sort(Enum.map(article.tags, & &1.name)) == ["ash", "elixir"]
      assert Ash.count!(Tag) == 2
    end

    test "an existing tag is related, not duplicated (on_lookup: :relate)" do
      actor = build_user()
      build_tag("elixir")

      {:ok, article} =
        publish(actor, %{
          title: "Reuse #{uniq()}",
          description: "d",
          body_raw: "b",
          tags: [%{name: "elixir"}]
        })

      # Matched by the `unique_name` identity, so no second row is inserted.
      assert Ash.count!(Tag) == 1
      article = Ash.load!(article, :tags)
      assert Enum.map(article.tags, & &1.name) == ["elixir"]
    end
  end

  describe "update (update :update, author only)" do
    test "the author can update; the slug and body are recomputed" do
      author = build_user()

      {:ok, article} =
        publish(author, %{title: "Original #{uniq()}", description: "d", body_raw: "b"})

      new_title = "Updated #{uniq()}"

      {:ok, updated} =
        article
        |> Ash.Changeset.for_update(:update, %{title: new_title, body_raw: "## New body"},
          actor: author
        )
        |> Ash.update()

      assert updated.slug == Slug.slugify(new_title)
      assert updated.body =~ "<h2>"
    end

    test "dropping a tag unrelates it but keeps the Tag row (on_missing: :unrelate)" do
      author = build_user()

      {:ok, article} =
        publish(author, %{
          title: "Retag #{uniq()}",
          description: "d",
          body_raw: "b",
          tags: [%{name: "keep"}, %{name: "drop"}]
        })

      {:ok, updated} =
        article
        |> Ash.Changeset.for_update(:update, %{tags: [%{name: "keep"}]}, actor: author)
        |> Ash.update()

      updated = Ash.load!(updated, :tags)
      assert Enum.map(updated.tags, & &1.name) == ["keep"]
      # `:unrelate` detaches the tag; it does not destroy the Tag itself.
      assert Ash.count!(Tag) == 2
    end

    test "a non-author cannot update the article (Forbidden)" do
      author = build_user()
      other = build_user()

      {:ok, article} =
        publish(author, %{title: "Owned #{uniq()}", description: "d", body_raw: "b"})

      # Update policy is `relates_to_actor_via(:user)`. The tuple form returns
      # a Forbidden error; the bang form (`Ash.update!`) would raise it.
      assert {:error, %Ash.Error.Forbidden{}} =
               article
               |> Ash.Changeset.for_update(:update, %{title: "hijacked #{uniq()}"}, actor: other)
               |> Ash.update()
    end

    test "Ash.can?/2 reports the policy result without performing the action" do
      author = build_user()
      other = build_user()

      {:ok, article} =
        publish(author, %{title: "Perm #{uniq()}", description: "d", body_raw: "b"})

      assert Ash.can?({article, :update}, author)
      refute Ash.can?({article, :update}, other)
    end
  end

  describe "aggregates and calculations" do
    test "favorites_count reflects the number of favorites" do
      article = build_article(build_user())
      favorite_article(build_user(), article)
      favorite_article(build_user(), article)

      # Aggregates are derived data, loaded on demand.
      assert Ash.load!(article, :favorites_count).favorites_count == 2
    end

    test "is_favorited is true only for a user who favorited the article" do
      fan = build_user()
      stranger = build_user()
      article = build_article(build_user())
      favorite_article(fan, article)

      # The calculation takes a required `actor_id` argument.
      assert Ash.load!(article, is_favorited: %{actor_id: fan.id}).is_favorited == true
      assert Ash.load!(article, is_favorited: %{actor_id: stranger.id}).is_favorited == false
    end
  end

  describe "destroy_article/2 (author only)" do
    test "the author can destroy their own article" do
      author = build_user()
      article = build_article(author)

      assert :ok = Articles.destroy_article(article, actor: author)
    end

    test "a non-author cannot destroy it (Forbidden)" do
      other = build_user()
      article = build_article(build_user())

      assert {:error, %Ash.Error.Forbidden{}} = Articles.destroy_article(article, actor: other)
    end
  end
end
