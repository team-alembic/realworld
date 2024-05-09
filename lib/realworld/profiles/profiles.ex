defmodule Realworld.Profiles do
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Profiles.Follow
  end
end
