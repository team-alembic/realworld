defmodule Realworld.Articles.Changes.SlugifyTitle do
  use Ash.Resource.Change
  alias Ash.Changeset

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _options, _context) do
    slug =
      changeset
      |> Changeset.get_attribute(:title)
      |> maybe_slugify()

    Changeset.change_attribute(changeset, :slug, slug)
  end

  defp maybe_slugify(title) when is_binary(title), do: Slug.slugify(title)
  defp maybe_slugify(_), do: ""
end
