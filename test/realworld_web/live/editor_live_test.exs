defmodule RealworldWeb.EditorLiveTest do
  @moduledoc """
  LiveView tests for the article editor (`EditorLive.Index`), focused on
  authentication gating and that the form renders for authors.
  """
  use RealworldWeb.ConnCase, async: false

  test "guests are redirected away from the editor", %{conn: conn} do
    conn
    |> visit(~p"/editor")
    |> assert_path(~p"/")
  end

  describe "as a signed-in user" do
    setup :register_and_log_in_user

    test "the editor form is shown", %{conn: conn} do
      conn
      |> visit(~p"/editor")
      |> assert_has("button", text: "Publish Article")
    end
  end
end
