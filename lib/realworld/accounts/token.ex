defmodule Realworld.Accounts.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Accounts

  postgres do
    table "tokens"
    repo Realworld.Repo
  end

  policies do
    # Tokens are internal to AshAuthentication (session revocation via :jti,
    # sign-in tokens). Its machinery flags every access with a private context,
    # so allow that and deny everything else.
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy always() do
      forbid_if always()
    end
  end
end
