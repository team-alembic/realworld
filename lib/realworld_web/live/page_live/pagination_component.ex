defmodule RealworldWeb.PageLive.PaginationComponent do
  use RealworldWeb, :live_component

  def active_class(on_page, active_page) when on_page == active_page, do: "active"
  def active_class(_on_page, _active_page), do: ""
end
