defmodule Realworld.Accounts do
  @moduledoc """
  The Accounts domain: users and their authentication tokens.

  Registration and sign-in are not hand-written — the `AshAuthentication`
  extension on `User` adds the `:register_with_password` and
  `:sign_in_with_password` actions. See `Realworld.Accounts.UserTest` for a
  worked tour of both plus the self-only update policy.
  """
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Accounts.Token

    resource Realworld.Accounts.User do
      define :get_user_by_username, action: :get_by_username, args: [:username]
    end
  end
end
