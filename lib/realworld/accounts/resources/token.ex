defmodule Realworld.Accounts.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  token do
    api(Realworld.Accounts)
  end

  postgres do
    table("tokens")
    repo(Realworld.Repo)
  end
end
