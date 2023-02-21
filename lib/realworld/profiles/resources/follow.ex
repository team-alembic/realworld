defmodule Realworld.Profiles.Follow do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

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

  code_interface do
    define_for Realworld.Profiles

    define :following, args: [:target_id]
    define :create_following, args: [:target_id]
    define :list_followings
  end

  actions do
    defaults [:read, :destroy]

    read :list_followings do
      filter expr(user_id == ^actor(:id))
    end

    read :following do
      get? true

      argument :target_id, :uuid do
        allow_nil? false
      end

      filter expr(user_id == ^actor(:id) and target_id == ^arg(:target_id))
    end

    create :create_following do
      argument :target_id, :uuid do
        allow_nil? false
      end

      change relate_actor(:user)
      change manage_relationship(:target_id, :target, type: :append)
    end
  end

  attributes do
    uuid_primary_key :id

    create_timestamp :created_at
  end

  relationships do
    belongs_to :user, Realworld.Accounts.User do
      api Realworld.Accounts
      allow_nil? false
      primary_key? true
    end

    belongs_to :target, Realworld.Accounts.User do
      api Realworld.Accounts
      allow_nil? false
      primary_key? true
    end
  end
end
