defmodule RealworldWeb.ProfileLiveTest do
  @moduledoc """
  LiveView tests for the profile page (`ProfileLive.Index`), including a real
  `PhoenixTest` interaction: clicking the follow button and asserting the UI
  flips to "unfollow".
  """
  use RealworldWeb.ConnCase, async: false

  test "shows the profile and the user's articles", %{conn: conn} do
    # `bio` isn't accepted at registration; it's set through the :update action.
    user = build_user()
    {:ok, user} =
      user
      |> Ash.Changeset.for_update(:update, %{bio: "Elixir enthusiast"}, actor: user)
      |> Ash.update()

    build_article(user, title: "My First Post")

    conn
    |> visit(~p"/profile/#{user.username}")
    |> assert_has("h4", text: user.username)
    |> assert_has("p", text: "Elixir enthusiast")
    |> assert_has("h1", text: "My First Post")
  end

  describe "following" do
    setup :register_and_log_in_user

    test "a signed-in user can follow another user from their profile", %{conn: conn} do
      other = build_user()

      conn
      |> visit(~p"/profile/#{other.username}")
      # The follow button carries the target's name; after clicking, the
      # LiveView re-renders it as an unfollow button.
      |> click_button("Follow #{other.username}")
      |> assert_has("button", text: "Unfollow #{other.username}")
    end
  end
end
