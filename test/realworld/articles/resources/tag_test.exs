defmodule Realworld.Articles.TagTest do
  @moduledoc """
  Exercises the `Tag` resource: public reads, actor-gated creates, and the
  `unique_name` identity.

  Tags are normally created as a side effect of publishing an article (see the
  "tags via manage_relationship" tests in `Realworld.Articles.ArticleTest` —
  the managed relationship runs as the publishing actor, which is how it
  satisfies the create policy here).
  """
  use Realworld.DataCase, async: true

  alias Realworld.Articles.Tag

  defp create_tag(name, opts) do
    Tag
    |> Ash.Changeset.for_create(:create, %{name: name}, opts)
    |> Ash.create()
  end

  describe "create" do
    test "an actor can create a tag" do
      assert {:ok, tag} = create_tag("elixir", actor: build_user())
      assert tag.name == "elixir"
    end

    test "an anonymous create is Forbidden" do
      # The create policy is `actor_present()`. Unlike the resources that use
      # `relate_actor/1` (where a missing actor first fails validation as
      # Invalid), Tag has no actor-derived attributes, so the policy itself
      # rejects the request.
      assert {:error, %Ash.Error.Forbidden{}} = create_tag("elixir", [])
    end

    test "enforces the unique_name identity" do
      build_tag("elixir")

      assert {:error, %Ash.Error.Invalid{}} = create_tag("elixir", actor: build_user())
    end
  end

  describe "read" do
    test "tags are readable without an actor" do
      build_tag("phoenix")

      # The home page's tag sidebar renders for guests, so reads are public.
      assert {:ok, [tag]} = Ash.read(Tag, actor: nil)
      assert tag.name == "phoenix"
    end
  end
end
