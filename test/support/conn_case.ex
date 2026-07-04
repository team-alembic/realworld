defmodule RealworldWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use RealworldWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use RealworldWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      # High-level, driver-agnostic browsing API (works across dead views and LiveViews)
      import PhoenixTest
      import RealworldWeb.ConnCase
      # Data builders (build_user/1, build_article/2, favorite_article/2, ...)
      import Realworld.DataCase,
        only: [
          build_user: 0,
          build_user: 1,
          build_article: 1,
          build_article: 2,
          build_tag: 1,
          favorite_article: 2
        ]

      # The default endpoint for testing
      @endpoint RealworldWeb.Endpoint
    end
  end

  setup tags do
    Realworld.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Registers a fresh user and returns a connection logged in as them.

  Use as a `setup`: `setup :register_and_log_in_user` makes `%{conn: conn, user: user}`
  available to the test.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Realworld.DataCase.build_user()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Puts `user` into the connection's session the same way `AuthController` does
  on a successful sign in, so subsequent requests/LiveViews see `current_user`.
  """
  def log_in_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> AshAuthentication.Plug.Helpers.store_in_session(user)
  end
end
