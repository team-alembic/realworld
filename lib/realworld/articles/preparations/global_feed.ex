defmodule Realworld.Articles.Article.Preparations.GlobalFeed do
  use Ash.Resource.Preparation
  require Ash.Query
  alias Realworld.Profiles.Follow

  def prepare(query, _, %{actor: actor}) do
    {:ok, followings} = Follow.list_followings(actor: %{id: actor.id})

    authors_ids = followings
    |> Enum.map(& &1.target_id)


    query
    |> Ash.Query.filter(exists(user, id in ^authors_ids))
    |> Ash.Query.sort([created_at: :desc], prepend?: true)
    |> Ash.Query.load([
      :user,
      :tags,
      :favorites_count,
      is_favorited: %{actor_id: actor.id}
    ])
  end
end
