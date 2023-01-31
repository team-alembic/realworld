defmodule Realworld.Accounts.Registry do
  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry Realworld.Accounts.Ticket
  end
end
