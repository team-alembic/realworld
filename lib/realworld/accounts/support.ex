defmodule Realworld.Accounts do
  use Ash.Api

  resources do
    registry Realworld.Accounts.Registry
  end
end
