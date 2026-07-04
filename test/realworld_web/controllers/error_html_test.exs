defmodule RealworldWeb.ErrorHTMLTest do
  use RealworldWeb.ConnCase, async: true

  test "renders 404" do
    assert RealworldWeb.ErrorHTML.render("404.html", %{}) == "Not Found"
  end

  test "renders 500" do
    assert RealworldWeb.ErrorHTML.render("500.html", %{}) == "Internal Server Error"
  end
end
