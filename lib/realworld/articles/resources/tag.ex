defmodule Realworld.Articles.Tag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tags"
    repo Realworld.Repo
  end

  actions do
    defaults [:create, :read, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_name, [:name]
  end
end
