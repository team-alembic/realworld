defmodule Realworld.Profiles do
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Profiles.Follow do
      define :following, args: [:target_id]
      define :follow, args: [:target_id]
      define :unfollow, args: [:target_id], require_reference?: false, get?: true
      define :list_followings, args: [:target_id]
    end
  end
end
