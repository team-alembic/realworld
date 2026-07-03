defmodule Realworld.Profiles.FollowTest do
  @moduledoc """
  Exercises the Profiles domain (the `Follow` resource) and doubles as a worked
  example of testing Ash actions.

  Concepts demonstrated here:

    * calling actions through a **domain code interface** (`Profiles.follow/2`)
    * passing an **actor** so policies and `relate_actor/1` can resolve the
      current user
    * **upsert** actions (`upsert_identity`) making `follow` idempotent
    * **`get?` reads** that return a single record or `nil`
    * a custom read whose results are scoped to the actor (`list_followings`)
    * **authorization failures** surfacing as `Ash.Error.Forbidden`
    * loading relationships back onto `User` with `Ash.load!/2`
  """
  use Realworld.DataCase, async: true

  alias Realworld.Profiles
  alias Realworld.Profiles.Follow

  describe "follow/2 (create :follow)" do
    test "one user can follow another" do
      follower = build_user()
      target = build_user()

      # The code interface `define :follow, args: [:target_id]` turns the
      # `:follow` action into `Profiles.follow(target_id, opts)`. The actor
      # becomes the follower via `change relate_actor(:user)`.
      assert {:ok, follow} = Profiles.follow(target.id, actor: follower)
      assert follow.user_id == follower.id
      assert follow.target_id == target.id
    end

    test "following twice is idempotent (upsert on :unique_follow)" do
      follower = build_user()
      target = build_user()

      assert {:ok, _} = Profiles.follow(target.id, actor: follower)
      assert {:ok, _} = Profiles.follow(target.id, actor: follower)

      # `upsert? true` + `upsert_identity :unique_follow` means the second call
      # updates the existing row instead of inserting a duplicate.
      assert Ash.count!(Follow) == 1
    end

    test "requires an actor" do
      target = build_user()

      # Without an actor, `relate_actor(:user)` cannot set the required
      # follower relationship (`:user` is `allow_nil? false`), so the action
      # fails with an Invalid error. (The create policy also requires an actor.)
      assert {:error, %Ash.Error.Invalid{}} = Profiles.follow(target.id)
    end
  end

  describe "following/2 (read :following, get? true)" do
    test "returns the follow record when the actor follows the target" do
      follower = build_user()
      target = build_user()
      {:ok, _} = Profiles.follow(target.id, actor: follower)

      # `get? true` reads return a single record (or nil) rather than a list.
      assert {:ok, %Follow{} = follow} = Profiles.following(target.id, actor: follower)
      assert follow.target_id == target.id
    end

    test "a `get?` read reports not-following as NotFound (or nil on request)" do
      follower = build_user()
      target = build_user()

      # By default a `get?` read returns a NotFound error when nothing matches.
      assert {:error, %Ash.Error.Invalid{}} = Profiles.following(target.id, actor: follower)

      # Pass `not_found_error?: false` to get `{:ok, nil}` instead — the
      # idiomatic way to write an "is X following Y?" check without rescuing.
      assert {:ok, nil} = Profiles.following(target.id, actor: follower, not_found_error?: false)
    end
  end

  describe "list_followings/1 (read :list_followings)" do
    test "returns only the follows belonging to the actor" do
      follower = build_user()
      other = build_user()
      target_a = build_user()
      target_b = build_user()

      {:ok, _} = Profiles.follow(target_a.id, actor: follower)
      {:ok, _} = Profiles.follow(target_b.id, actor: follower)
      # `other`'s follow must not leak into `follower`'s list.
      {:ok, _} = Profiles.follow(target_a.id, actor: other)

      # The action filters `user_id == ^actor(:id)`, so results are scoped to
      # the actor. Equivalent to calling the action directly:
      #   Ash.read!(Follow, action: :list_followings, actor: follower)
      assert {:ok, follows} = Profiles.list_followings(actor: follower)
      assert length(follows) == 2
      assert Enum.all?(follows, &(&1.user_id == follower.id))
    end
  end

  describe "unfollow/2 (destroy :unfollow)" do
    test "removes only the actor's own follow of the target" do
      alice = build_user()
      bob = build_user()
      target = build_user()

      {:ok, _} = Profiles.follow(target.id, actor: alice)
      {:ok, _} = Profiles.follow(target.id, actor: bob)

      # `change filter(...)` on the destroy scopes it to (actor, target), so
      # Alice unfollowing does not touch Bob's follow. `return_destroyed?: true`
      # returns the removed record.
      assert {:ok, _} = Profiles.unfollow(target.id, actor: alice, return_destroyed?: true)

      assert {:ok, nil} = Profiles.following(target.id, actor: alice, not_found_error?: false)
      assert {:ok, %Follow{}} = Profiles.following(target.id, actor: bob)
    end
  end

  describe "User <-> Follow relationships" do
    test "followers and followings load through the join in both directions" do
      alice = build_user()
      bob = build_user()
      carol = build_user()

      # alice follows bob and carol; bob follows carol.
      {:ok, _} = Profiles.follow(bob.id, actor: alice)
      {:ok, _} = Profiles.follow(carol.id, actor: alice)
      {:ok, _} = Profiles.follow(carol.id, actor: bob)

      # `has_many :followings` uses the default `user_id`; `has_many :followers`
      # overrides the destination attribute to `target_id`.
      alice = Ash.load!(alice, :followings)
      carol = Ash.load!(carol, :followers)

      assert length(alice.followings) == 2
      assert length(carol.followers) == 2
    end
  end
end
