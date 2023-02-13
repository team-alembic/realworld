defmodule Realworld.Profiles.Registry do
  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry Realworld.Profiles.Follow
  end
end
