defmodule Realworld.Articles.Article do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Articles

  postgres do
    table "articles"
    repo Realworld.Repo
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:user)
    end
  end

  actions do
    defaults [:read, :destroy]

    read :list_articles do
      argument :filter, :map, allow_nil?: true
      argument :private_feed?, :boolean, allow_nil?: false, default: false

      pagination do
        default_limit 20
        offset? true
        countable :by_default
      end

      prepare Realworld.Articles.Article.Preparations.FilterSortFeed
    end

    create :publish do
      primary? true
      accept [:title, :description, :body_raw]

      argument :tags, {:array, :map}, allow_nil?: true
      change manage_relationship(:tags, on_lookup: :relate, on_no_match: :create)

      change relate_actor(:user)

      change Realworld.Articles.Changes.SlugifyTitle
      change Realworld.Articles.Changes.RenderMarkdown
    end

    update :update do
      primary? true
      require_atomic? false
      accept [:title, :description, :body_raw]

      argument :tags, {:array, :map}, allow_nil?: true

      change manage_relationship(:tags,
               on_lookup: :relate,
               on_no_match: :create,
               on_missing: :unrelate
             )

      change Realworld.Articles.Changes.SlugifyTitle
      change Realworld.Articles.Changes.RenderMarkdown
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
      allow_nil? false
      public? true
    end

    attribute :body_raw, :string do
      allow_nil? false
      default ""
      public? true
    end

    attribute :body, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_slug, [:slug]
  end

  aggregates do
    count :favorites_count, :favorites
  end

  calculations do
    calculate :is_favorited, :boolean, expr(exists(favorites, id == ^arg(:actor_id))) do
      argument :actor_id, :uuid do
        allow_nil? false
      end
    end
  end

  relationships do
    has_many :comments, Realworld.Articles.Comment

    belongs_to :user, Realworld.Accounts.User do
      writable? true
      allow_nil? false
    end

    many_to_many :tags, Realworld.Articles.Tag do
      through Realworld.Articles.ArticleTag
      source_attribute_on_join_resource :article_id
      destination_attribute_on_join_resource :tag_id
    end

    has_many :favorite_links, Realworld.Articles.Favorite

    many_to_many :favorites, Realworld.Accounts.User do
      join_relationship :favorite_links
      source_attribute_on_join_resource :article_id
      destination_attribute_on_join_resource :user_id
    end
  end
end
