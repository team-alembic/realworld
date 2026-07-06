defmodule Realworld.Articles.Article.Preparations.FilterSortFeed do
  @moduledoc """
  Query logic for the `:list_articles` action: applies the optional `filter`
  argument (by tag, author or favouriter), restricts the personal feed to
  followed authors when `private_feed?` is set, sorts newest-first, and loads
  what the feed cards render.

  A preparation keeps this out of the calling code — the web layer just says
  `Articles.list_articles(%{filter: ...}, actor: user)`. Note the two
  `prepare/3` clauses: anonymous readers skip the actor-dependent
  `is_favorited` load.
  """
  use Ash.Resource.Preparation
  require Ash.Query

  def prepare(query, _, %{actor: nil}) do
    query
    |> filter_by_tag()
    |> filter_by_author()
    |> filter_by_favourited()
    |> Ash.Query.sort([created_at: :desc], prepend?: true)
    |> Ash.Query.load([:user, :tags, :favorites_count])
  end

  def prepare(query, _, %{actor: actor}) do
    query
    |> filter_by_tag()
    |> filter_by_author()
    |> filter_by_favourited()
    |> filter_followed(actor)
    |> Ash.Query.sort([created_at: :desc], prepend?: true)
    |> Ash.Query.load([
      :user,
      :tags,
      :favorites_count,
      is_favorited: %{actor_id: actor.id}
    ])
  end

  defp filter_followed(query, actor) do
    if query.arguments.private_feed? do
      Ash.Query.filter(query, exists(user.followers, user_id == ^actor.id))
    else
      query
    end
  end

  defp filter_by_tag(query) do
    case Ash.Changeset.get_argument(query, :filter) do
      %{tag: tag} ->
        Ash.Query.filter(query, exists(tags, name == ^tag))

      _ ->
        query
    end
  end

  defp filter_by_author(query) do
    case Ash.Changeset.get_argument(query, :filter) do
      %{author: author} ->
        Ash.Query.filter(query, exists(user, id == ^author))

      _ ->
        query
    end
  end

  defp filter_by_favourited(query) do
    case Ash.Changeset.get_argument(query, :filter) do
      %{favourited: favourited} ->
        Ash.Query.filter(query, exists(favorites, id == ^favourited))

      _ ->
        query
    end
  end
end
