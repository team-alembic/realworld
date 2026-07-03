defmodule RealworldWeb.PageLiveTest do
  @moduledoc """
  LiveView tests for the home page (`PageLive.Index`), written with the
  `PhoenixTest` library. `PhoenixTest` gives a single high-level API
  (`visit/2`, `assert_has/3`, `click_button/2`, ...) that works the same whether
  a route is a dead view or a LiveView, and it follows redirects for you.

  Authentication is set up through the session (see `ConnCase.log_in_user/2`),
  mirroring what `AuthController` does on a real sign in.

  Note: the navbar lives in the *root layout*, which is not part of the
  connected LiveView's DOM, so these tests assert on content the LiveView itself
  renders (the banner, the feed toggle, article cards) rather than nav links.
  """
  use RealworldWeb.ConnCase, async: false

  describe "as a guest" do
    test "the home page shows the banner and the global feed", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_has("h1", text: "conduit")
      |> assert_has("p", text: "A place to share your knowledge.")
      |> assert_has(".nav-link", text: "Global Feed")
      # The personal feed toggle is only rendered for signed-in users.
      |> refute_has(".nav-link", text: "Your Feed")
    end

    test "visiting an authenticated-only page redirects home", %{conn: conn} do
      # The `:require_authenticated_user` plug redirects guests to "/".
      conn
      |> visit(~p"/settings")
      |> assert_path(~p"/")
    end

    test "published articles appear in the global feed", %{conn: conn} do
      article = build_article(build_user(), title: "A Very Findable Title")

      conn
      |> visit(~p"/")
      |> assert_has("h1", text: article.title)
    end
  end

  describe "as a signed-in user" do
    setup :register_and_log_in_user

    test "the personal feed toggle replaces the guest banner", %{conn: conn} do
      conn
      |> visit(~p"/")
      # The guest banner is hidden once you're signed in...
      |> refute_has("p", text: "A place to share your knowledge.")
      # ...and the "Your Feed" toggle appears alongside the global feed.
      |> assert_has(".nav-link", text: "Your Feed")
      |> assert_has(".nav-link", text: "Global Feed")
    end
  end
end
