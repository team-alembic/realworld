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
    setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the Ecto sandbox for a test.

  Shared (non-async) mode lets other processes — e.g. a LiveView spawned during
  a `PhoenixTest` run — use the same connection, so `ConnCase` reuses this.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Realworld.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  # Simple, dependency-free generators. `System.unique_integer/1` guarantees a
  # process-wide unique, monotonically increasing value, so these satisfy the
  # `unique_email`/`unique_username` identities without a fixture library.
  def email, do: "user#{unique()}@example.com"

  def username, do: "user#{unique()}"

  def password, do: "password#{unique()}"

  defp unique, do: System.unique_integer([:positive])

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
      |> Ash.create!()

    user
  end

  @doc """
  Publishes an article authored by `actor`.

  A thin wrapper over the `:publish` action for arranging setup data (e.g. a
  feed of articles). Tests that are specifically *about* publishing call the
  action directly so the mechanics stay visible.
  """
  def build_article(actor, attrs \\ []) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:title, "Article #{unique()}")
      |> Map.put_new(:description, "A description")
      |> Map.put_new(:body_raw, "Some **markdown** body.")

    Realworld.Articles.Article
    |> Ash.Changeset.for_create(:publish, attrs, actor: actor)
    |> Ash.create!()
  end

  @doc """
  Creates a tag directly. Tag creation requires an actor (its create policy is
  `actor_present()`), but for arranging test data we skip authorization with
  `authorize?: false` — the standard escape hatch for setup code that isn't
  the behavior under test.
  """
  def build_tag(name) do
    Realworld.Articles.Tag
    |> Ash.Changeset.for_create(:create, %{name: name})
    |> Ash.create!(authorize?: false)
  end

  @doc """
  Favorites `article` as `user` via the domain code interface.
  """
  def favorite_article(user, article) do
    Realworld.Articles.favorite!(article.id, actor: user)
  end
end
