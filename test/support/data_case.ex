defmodule Realworld.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AshHq.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Realworld.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Realworld.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Realworld.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  def email, do: Faker.Internet.email()

  def username, do: Faker.Internet.user_name()

  def password, do: Faker.Lorem.words(4) |> Enum.join(" ")

  def build_user(attrs \\ []) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:email, email())
      |> Map.put_new(:username, username())
      |> Map.put_new(:password, password())

    user =
      Realworld.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, attrs)
      |> Realworld.Accounts.create!()

    user
  end
end
