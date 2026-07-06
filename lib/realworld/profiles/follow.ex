defmodule Realworld.Profiles.Follow do
  @moduledoc """
  One user following another — the same "join with an upsert" shape as
  `Realworld.Articles.Favorite`, pointing at User on both ends (`:user`
  follows `:target`).

  `User` exposes both directions: `has_many :followings` (default foreign
  key) and `has_many :followers` (overriding `destination_attribute` to
  `:target_id`). See `Realworld.Profiles.FollowTest`.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Profiles

  resource do
    description "One user (:user) following another (:target)."
  end

  postgres do
    table "follows"
    repo Realworld.Repo
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:user)
    end
  end

  actions do
    defaults [:read]

    read :list_followings do
      description "Everyone the actor follows."
      filter expr(user_id == ^actor(:id))
    end

    read :following do
      description "Does the actor follow this user? A get? read scoped to the actor."
      get? true

      argument :target_id, :uuid do
        allow_nil? false
      end

      filter expr(user_id == ^actor(:id) and target_id == ^arg(:target_id))
    end

    create :follow do
      description "Follow a user as the actor — idempotent thanks to the upsert."

      argument :target_id, :uuid do
        allow_nil? false
      end

      upsert? true
      upsert_identity :unique_follow

      change relate_actor(:user)
      change manage_relationship(:target_id, :target, type: :append)
    end

    destroy :unfollow do
      description "Remove the actor's own follow of a user."

      argument :target_id, :uuid do
        allow_nil? false
      end

      change filter(expr(target_id == ^arg(:target_id)))
      change filter(expr(user_id == ^actor(:id)))
    end
  end

  identities do
    identity :unique_follow, [:target_id, :user_id]
  end

  attributes do
    uuid_primary_key :id

    create_timestamp :created_at
  end

  relationships do
    belongs_to :user, Realworld.Accounts.User do
      allow_nil? false
      primary_key? true
    end

    belongs_to :target, Realworld.Accounts.User do
      allow_nil? false
      primary_key? true
    end
  end
end
