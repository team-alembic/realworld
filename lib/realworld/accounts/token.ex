defmodule Realworld.Accounts.Token do
  @moduledoc """
  Storage for AshAuthentication's tokens (sign-in tokens, revocation records).

  Everything here is managed by the `TokenResource` extension — there is no
  primary `:read`, only purpose-built actions like `:revoke_token` and
  `:read_expired`. Deny-by-default policies keep it that way; see
  `Realworld.Accounts.TokenTest` for how the bypass works.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer],
    domain: Realworld.Accounts

  resource do
    description "AshAuthentication token storage — fully managed by the TokenResource extension."
  end

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
