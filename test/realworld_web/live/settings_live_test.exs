defmodule RealworldWeb.SettingsLiveTest do
  @moduledoc """
  LiveView tests for the settings page (`SettingsLive.Index`): authentication
  gating, form prefill, and that a failed save is survivable.

  The settings inputs are placeholder-only (no `<label>`s yet), so the
  submission test drops down to `Phoenix.LiveViewTest` via `unwrap/2` rather
  than using `PhoenixTest.fill_in/3` (which targets inputs by label).
  """
  use RealworldWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  test "guests are redirected away from settings", %{conn: conn} do
    conn
    |> visit(~p"/settings")
    |> assert_path(~p"/")
  end

  describe "as a signed-in user" do
    setup :register_and_log_in_user

    test "the settings form is prefilled with the current user's email", %{conn: conn, user: user} do
      conn
      |> visit(~p"/settings")
      |> assert_has("button", text: "Update Settings")
      |> assert_has("input[value='#{user.email}']")
    end

    test "updating your username redirects to your new profile", %{conn: conn, user: user} do
      new_username = "renamed#{System.unique_integer([:positive])}"

      conn
      |> visit(~p"/settings")
      |> unwrap(fn view ->
        view
        |> form("#settings-form", %{
          "user" => %{"username" => new_username, "email" => to_string(user.email)}
        })
        |> render_submit()
      end)
      |> assert_path(~p"/profile/#{new_username}")
    end

    test "a failed save keeps you on settings instead of crashing", %{conn: conn} do
      # The `unique_email` identity rejects the update at the data layer.
      other = build_user()

      # Regression: the {:error, form} branch used to return a bare socket
      # (missing {:noreply, ...}), which crashed the LiveView. Surfacing the
      # error message in the form is still on the backlog — for now the page
      # must survive and keep rendering.
      conn
      |> visit(~p"/settings")
      |> unwrap(fn view ->
        view
        |> form("#settings-form", %{"user" => %{"email" => to_string(other.email)}})
        |> render_submit()
      end)
      |> assert_path(~p"/settings")
      |> assert_has("button", text: "Update Settings")
    end
  end
end
