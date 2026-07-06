defmodule Realworld.Articles.Changes.SlugifyTitle do
  @moduledoc """
  Derives `:slug` from `:title` in a `before_action` hook, so publishing
  "Hello World!" yields the `hello-world` URL. Runs on update too — renaming
  an article changes its slug (the `unique_slug` identity guarantees no
  collisions).
  """
  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _options, _context) do
    Changeset.before_action(changeset, &maybe_slugify_title/1)
  end

  defp maybe_slugify_title(changeset) do
    case Changeset.get_attribute(changeset, :title) do
      title when is_binary(title) ->
        Changeset.force_change_attribute(changeset, :slug, Slug.slugify(title))

      _ ->
        changeset
    end
  end
end
