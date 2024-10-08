defmodule Realworld.Repo.Migrations.AddUniqueFavorites do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create unique_index(:favorites, [:user_id, :article_id],
             name: "favorites_unique_favorite_index"
           )
  end

  def down do
    drop_if_exists(
      unique_index(:favorites, [:user_id, :article_id], name: "favorites_unique_favorite_index")
    )
  end
end
