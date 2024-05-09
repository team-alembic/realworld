defmodule Realworld.Accounts do
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Accounts.Token
    resource Realworld.Accounts.User
  end
end
