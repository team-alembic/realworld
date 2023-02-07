defmodule Realworld.Articles do
  use Ash.Api, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    registry Realworld.Articles.Registry
  end
end
