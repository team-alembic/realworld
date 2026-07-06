defmodule Realworld.Articles.Article do
  @moduledoc """
  An article, the heart of the app. The busiest resource here and the best
  place to read about:

    * **policies** — public reads, author-only updates/destroys via
      `relates_to_actor_via(:user)`
    * **derived attributes** via changes: `SlugifyTitle` writes `:slug` and
      `RenderMarkdown` renders sanitized HTML into `:body` from the
      user-supplied `:body_raw` (the only body field actions `accept`)
    * **`manage_relationship`** — the `tags` argument looks up existing tags,
      creates missing ones, and (on update) unrelates dropped ones
    * a **paginated, filtered read** (`:list_articles`) whose logic lives in
      the `FilterSortFeed` preparation
    * an **aggregate** (`favorites_count`) and a **calculation**
      (`is_favorited`) — derived at read time, never stored

  `Realworld.Articles.ArticleTest` walks through all of this with running
  examples.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Articles

  resource do
    description "An article published by a user, with tags, comments and favorites."
  end

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
      description "The paginated feed, filterable by tag/author/favouriter, with a followed-authors-only mode."

      argument :filter, :map,
        allow_nil?: true,
        description:
          "Optional filters: %{tag: name}, %{author: user_id} or %{favourited: user_id}."

      argument :private_feed?, :boolean,
        allow_nil?: false,
        default: false,
        description: "When true, only articles by authors the actor follows."

      pagination do
        default_limit 20
        offset? true
        countable :by_default
      end

      prepare Realworld.Articles.Article.Preparations.FilterSortFeed
    end

    create :publish do
      description "Publish a new article authored by the actor; derives the slug and renders the markdown body."
      primary? true
      accept [:title, :description, :body_raw]

      argument :tags, {:array, :map},
        allow_nil?: true,
        description:
          "Tag names to attach, e.g. [%{name: \"elixir\"}]; existing tags are reused, new ones created."

      change manage_relationship(:tags, on_lookup: :relate, on_no_match: :create)

      change relate_actor(:user)

      change Realworld.Articles.Changes.SlugifyTitle
      change Realworld.Articles.Changes.RenderMarkdown
    end

    update :update do
      description "Author-only edit; re-derives the slug, re-renders the markdown and syncs tags (dropped tags are unrelated)."
      primary? true
      require_atomic? false
      accept [:title, :description, :body_raw]

      argument :tags, {:array, :map},
        allow_nil?: true,
        description: "The full desired tag list; anything missing from it is unrelated."

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
      description "URL identifier derived from the title by SlugifyTitle — never accepted from input."
      allow_nil? false
      public? true
    end

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
      description "The one-line teaser shown on feed cards."
      allow_nil? false
      public? true
    end

    attribute :body_raw, :string do
      description "The markdown source the author writes — the only body field actions accept."
      allow_nil? false
      default ""
      public? true
    end

    attribute :body, :string do
      description "Sanitized HTML rendered from body_raw by RenderMarkdown — never accepted from input."
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
    count :favorites_count, :favorites do
      description "How many users favorited this article — computed at read time, never stored."
    end
  end

  calculations do
    calculate :is_favorited, :boolean, expr(exists(favorites, id == ^arg(:actor_id))) do
      description "Whether the given user favorited this article; load with is_favorited: %{actor_id: user.id}."

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
