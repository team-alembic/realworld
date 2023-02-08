defmodule Realworld.Articles.Changes.SlugifyTitle do
  use Ash.Resource.Change
  alias Ash.Changeset

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _options, _context) do
    slug = changeset |> Changeset.get_attribute(:title) |> slugify()
    Changeset.change_attribute(changeset, :slug, slug)
  end

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^\w-]+/u, "-")
    |> String.replace(~r/^-+|-+$/u, "")
  end
end
