defmodule Realworld.Articles.Tag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Realworld.Articles

  postgres do
    table "tags"
    repo Realworld.Repo
  end

  actions do
    defaults [:read, :destroy, create: [:name]]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_name, [:name]
  end
end
