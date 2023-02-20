defmodule Realworld.Profiles.Follow do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "follows"
    repo Realworld.Repo
  end

  code_interface do
    define_for Realworld.Profiles

    #TODO: do not pass user_id as arg, get it from actor_id
    define :following?, args: [:user_id, :target_id]
    define :create_following, args: [:user_id, :target_id]
    define :list_followings
  end

  actions do
    defaults [:destroy]

    read :list_followings do
      filter expr(user_id == ^actor(:id))
    end

    read :following? do
      get? true

      argument :user_id, :uuid do
        allow_nil? false
      end

      argument :target_id, :uuid do
        allow_nil? false
      end

      filter expr(user_id == ^arg(:user_id) and target_id == ^arg(:target_id))
    end

    create :create_following do
      argument :user_id, :uuid do
        allow_nil? false
      end

      argument :target_id, :uuid do
        allow_nil? false
      end

      change manage_relationship(:user_id, :user, type: :append)
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
