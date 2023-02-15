defmodule Realworld.Articles.Article.Preparations.FilterSortFeed do
  use Ash.Resource.Preparation

  def prepare(query, _, _) do
    query
    |> Ash.Query.sort([created_at: :desc], prepend?: true)
  end
end
