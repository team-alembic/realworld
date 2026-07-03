defmodule RealworldWeb.SettingsLiveTest do
  @moduledoc """
  LiveView tests for the settings page (`SettingsLive.Index`): authentication
  gating and that the form is pre-filled with the current user's details.
  """
  use RealworldWeb.ConnCase, async: false

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
  end
end
