defmodule RealworldWeb.PageController do
  use RealworldWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
