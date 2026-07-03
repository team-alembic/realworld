defmodule Realworld.Articles.CommentTest do
  @moduledoc """
  Exercises the `Comment` resource. Because the domain only exposes a
  `destroy_comment` code interface (no `create`), this file shows the
  **changeset style** of calling an action directly:

      Comment
      |> Ash.Changeset.for_create(:create, params, actor: user)
      |> Ash.create()

  It also covers `manage_relationship(type: :append)`, a custom argument-driven
  read (`comments_by_article`), the Forbidden-vs-Invalid error distinction, and
  the author-only destroy policy.
  """
  use Realworld.DataCase, async: true

  alias Realworld.Articles
  alias Realworld.Articles.Comment

  defp comment_on(article, user, body \\ "Nice article!") do
    Comment
    |> Ash.Changeset.for_create(:create, %{body: body, article_id: article.id}, actor: user)
    |> Ash.create()
  end

  describe "create :create" do
    test "relates the actor as author and links the article" do
      author = build_user()
      commenter = build_user()
      article = build_article(author)

      assert {:ok, comment} = comment_on(article, commenter, "Great read")
      assert comment.body == "Great read"

      # `relate_actor(:user)` sets the author; `manage_relationship(:article_id,
      # :article, type: :append)` links the existing article by id.
      comment = Ash.load!(comment, [:user, :article])
      assert comment.user.id == commenter.id
      assert comment.article.id == article.id
    end

    test "requires an actor" do
      article = build_article(build_user())

      # `relate_actor/1` defaults to `allow_nil?: false`, so without an actor
      # the author relationship can't be set and the create fails with an
      # Invalid error. (The create policy `actor_present()` would also deny it.)
      result =
        Comment
        |> Ash.Changeset.for_create(:create, %{body: "hi", article_id: article.id})
        |> Ash.create()

      assert {:error, %Ash.Error.Invalid{}} = result
    end

    test "requires a body (Invalid when missing)" do
      article = build_article(build_user())
      user = build_user()

      result =
        Comment
        |> Ash.Changeset.for_create(:create, %{article_id: article.id}, actor: user)
        |> Ash.create()

      assert {:error, %Ash.Error.Invalid{}} = result
    end

    test "requires the article_id argument (Invalid when missing)" do
      user = build_user()

      result =
        Comment
        |> Ash.Changeset.for_create(:create, %{body: "orphan"}, actor: user)
        |> Ash.create()

      assert {:error, %Ash.Error.Invalid{}} = result
    end
  end

  describe "read :comments_by_article" do
    test "returns only the comments for the given article" do
      author = build_user()
      commenter = build_user()
      article_a = build_article(author)
      article_b = build_article(author)

      {:ok, _} = comment_on(article_a, commenter, "on A")
      {:ok, _} = comment_on(article_a, commenter, "also on A")
      {:ok, _} = comment_on(article_b, commenter, "on B")

      # A custom read whose argument feeds the filter
      # `article_id == ^arg(:article_id)`.
      comments =
        Comment
        |> Ash.Query.for_read(:comments_by_article, %{article_id: article_a.id})
        |> Ash.read!()

      assert length(comments) == 2
      assert Enum.all?(comments, &(&1.article_id == article_a.id))
    end

    test "is readable without an actor (read policy is `always()`)" do
      article = build_article(build_user())
      {:ok, _} = comment_on(article, build_user())

      comments =
        Comment
        |> Ash.Query.for_read(:comments_by_article, %{article_id: article.id})
        |> Ash.read!(actor: nil)

      assert length(comments) == 1
    end
  end

  describe "destroy_comment/2 (author only)" do
    test "the author can destroy their own comment" do
      author = build_user()
      article = build_article(author)
      {:ok, comment} = comment_on(article, author)

      assert :ok = Articles.destroy_comment(comment, actor: author)
    end

    test "a non-author cannot destroy someone else's comment (Forbidden)" do
      article = build_article(build_user())
      commenter = build_user()
      stranger = build_user()
      {:ok, comment} = comment_on(article, commenter)

      # Destroy policy is `relates_to_actor_via(:user)`.
      assert {:error, %Ash.Error.Forbidden{}} =
               Articles.destroy_comment(comment, actor: stranger)
    end
  end
end
