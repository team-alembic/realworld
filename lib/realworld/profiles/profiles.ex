defmodule Realworld.Profiles do
  @moduledoc """
  The Profiles domain: who follows whom.

  A deliberately small domain — one resource, four code-interface functions —
  useful as the "hello world" of the pattern before reading
  `Realworld.Articles`.
  """
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Profiles.Follow do
      define :following, args: [:target_id]
      define :follow, args: [:target_id]
      define :unfollow, args: [:target_id], require_reference?: false, get?: true
      define :list_followings
    end
  end
end
