defmodule Realworld.Articles.Tag do
  @moduledoc """
  A tag name, unique across the app (`unique_name` identity).

  Tags are rarely created directly — they come into existence through
  Article's `manage_relationship(:tags, on_lookup: :relate, on_no_match:
  :create)` when someone publishes with a new tag. See
  `Realworld.Articles.TagTest`.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Articles

  resource do
    description "A tag name, unique across the app and shared by all articles that use it."
  end

  postgres do
    table "tags"
    repo Realworld.Repo
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    # Tags are created through Article's manage_relationship (:publish and
    # :update), which runs as the publishing actor — so this holds there too.
    policy action_type(:create) do
      authorize_if actor_present()
    end
  end

  actions do
    defaults [:read, create: [:name]]
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
