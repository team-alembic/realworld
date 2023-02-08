defmodule Realworld.Articles.Article do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "articles"
    repo Realworld.Repo
  end

  # code_interface do
  #   define_for Realworld.Articles

  #   define :publish, args: [:title, :description, :body, :user]
  # end

  actions do
    defaults [:read, :update, :destroy]

    create :publish do
      primary? true
      accept [:title, :description, :body]
      argument :user, :uuid, allow_nil?: false

      # ? confirm this approach
      change manage_relationship(:user, on_lookup: :relate, on_no_match: :error)

      # ? confirm this approach
      change Realworld.Articles.Changes.SlugifyTitle
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :slug, :string do
      allow_nil? false
    end

    attribute :title, :string do
      allow_nil? false
    end

    attribute :description, :string do
      allow_nil? false
    end

    attribute :body, :string do
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_slug, [:slug]
  end

  relationships do
    belongs_to :user, Realworld.Accounts.User do
      api Realworld.Accounts
      writable? true
      allow_nil? false
    end

    many_to_many :tag_list, Realworld.Articles.Tag do
      through Realworld.Articles.ArticleTag
      source_attribute_on_join_resource :article_id
      destination_attribute_on_join_resource :tag_id
    end
  end
end
