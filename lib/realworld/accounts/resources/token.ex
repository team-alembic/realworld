defmodule Realworld.Accounts.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    domain: Realworld.Accounts

  postgres do
    table "tokens"
    repo Realworld.Repo
  end
end
