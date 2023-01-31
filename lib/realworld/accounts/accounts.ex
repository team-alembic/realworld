defmodule Realworld.Accounts do
  use Ash.Api, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    registry Realworld.Accounts.Registry
  end
end
